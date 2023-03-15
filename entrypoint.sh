#!/usr/bin/env bash

# 设置各变量
WP=${WP:-'crgo'}
UUID=${UUID:-'be04add9-5c68-8bab-950c-08cd5320df18'}
URL=${RENDER_EXTERNAL_URL:8}
EXEC=$(echo $RANDOM | md5sum | head -c 6; echo)
generate_config() {
  cat > config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"${WP}l",
                        "dest":3002
                    },
                    {
                        "path":"${WP}",
                        "dest":3003
                    },
                    {
                        "path":"${WP}j",
                        "dest":3004
                    },
                    {
                        "path":"${WP}s",
                        "dest":3005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${WP}l"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${WP}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${WP}j"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${WP}s"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"6ICFrm60L5kPCm33A/sukf/c6kXazL+RIko+d/lPp24=",
                "address":[
                    "172.16.0.2/32",
                    "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "endpoint":"162.159.193.10:2408"
                    }
                ]
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > tunnel.json && echo -e "tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)\ncredentials-file: /app/tunnel.json" > tunnel.yml
  else
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"B4a-${URL%.b4a.run}-Vm-$v4l$v4\", \"add\": \"[2606:4700::]\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\${ARGO_DOMAIN}\", \"path\": \"${WP}?ed=2048\", \"tls\": \"tls\", \"sni\": \"\${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > list << EOF
*******************************************
V2-rayN:
----------------------------
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=${WP}l%3Fed%3D2048#B4a-${URL%.b4a.run}-Vl-$v4l$v4
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@[2606:4700::]:443?security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=${WP}j%3Fed%3D2048#B4a-${URL%.b4a.run}-Tj-$v4l$v4
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)@[2606:4700::]:443#$B4a-${URL%.b4a.run}-Ss-$v4l$v4
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: \${ARGO_DOMAIN} ，路径: ${WP}s?ed=2048 ， 传输层安全: tls ， sni: \${ARGO_DOMAIN}
*******************************************
小火箭:
----------------------------
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&type=ws&host=\${ARGO_DOMAIN}&path=${WP}l%3Fed%3D2048&sni=\${ARGO_DOMAIN}#B4a-${URL%.b4a.run}-Vl-$v4l$v4
----------------------------
vmess://$(echo "none:${UUID}@[2606:4700::]:443" | base64 -w0)?remarks=B4a-${URL%.b4a.run}-Vm-$v4l$v4&obfsParam=\${ARGO_DOMAIN}&path=${WP}%3Fed%3D2048&obfs=websocket&tls=1&peer=\${ARGO_DOMAIN}&alterId=0
----------------------------
trojan://${UUID}@[2606:4700::]:443?peer=\${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=\${ARGO_DOMAIN};obfs-uri=${WP}j%3Fed%3D2048#B4a-${URL%.b4a.run}-Tj-$v4l$v4
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)?obfs=wss&obfsParam=\${ARGO_DOMAIN}&path=${WP}s?ed=2048#B4a-${URL%.b4a.run}-Ss-$v4l$v4
*******************************************
Clash:
----------------------------
- {name: B4a-${URL%.b4a.run}-Vl-$v4l$v4, type: vless, server: [2606:4700::], port: 443, uuid: ${UUID}, tls: true, servername: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: ${WP}l?ed=2048, headers: { Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: B4a-${URL%.b4a.run}-Vm-$v4l$v4, type: vmess, server: [2606:4700::], port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: ${WP}?ed=2048, headers: {Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: B4a-${URL%.b4a.run}-Tj-$v4l$v4, type: trojan, server: [2606:4700::], port: 443, password: ${UUID}, udp: true, tls: true, sni: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: ${WP}j?ed=2048, headers: { Host: \${ARGO_DOMAIN} } } }
----------------------------
- {name: B4a-${URL%.b4a.run}-Ss-$v4l$v4, type: ss, server: [2606:4700::], port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: \${ARGO_DOMAIN}, path: ${WP}s?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF
  cat list
}

argo_type
export_list
ABC
}

generate_nezha() {
  cat > nz.sh << EOF
#!/usr/bin/env bash

# 检测是否已运行
check_run() {
  [[ \$(pgrep -laf nz${EXEC}) ]] && echo "哪吒客户端正在运行中" && exit
}

# 三个变量不全则不安装哪吒客户端
check_variable() {
  [[ -z "\${NS}" || -z "\${NP}" || -z "\${NK}" ]] && exit
}

# 下载最新版本 Nezha Agent
download_agent() {
  if [ ! -e nz${EXEC} ]; then
    #URL=\$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
    #wget -t 2 -T 10 -N \${URL}
    wget -t 4 -T 10 -N  -O -4 nezha-agent_linux_amd64.zip https://github.com/naiba/nezha/releases/latest/download/nezha-agent_linux_amd64.zip
    unzip -qod ./ nezha-agent_linux_amd64.zip && rm -f nezha-agent_linux_amd64.zip
    mv /app/nezha-agent /app/nz${EXEC}
  fi
}

check_run
check_variable
download_agent
EOF
}

generate_pm2_file() {
  if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
    [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --no-autoupdate --config tunnel.yml run"
    [[ $ARGO_AUTH =~ ^[A-Z0-9a-z]{120,250}$ ]] && ARGO_ARGS="tunnel --no-autoupdate run --token ${ARGO_AUTH}"
  else
    ARGO_ARGS="tunnel --no-autoupdate --logfile argo.log --loglevel info --url http://localhost:8080"
  fi

  if [[ -z "${NS}" || -z "${NP}" || -z "${NK}" ]]; then
    cat > ecosystem.config.js << EOF
  module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run"
      },
      {
          "name":"argo",
          "script":"cloudflared",
          "args":"${ARGO_ARGS}"
      }
  ]
}
EOF
  else
    cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run"
      },
      {
          "name":"argo",
          "script":"cloudflared",
          "args":"${ARGO_ARGS}"
      },
      {
          "name":"nezha",
          "script":"/app/nz${EXEC}",
          "args":"-s ${NS}:${NP} -p ${NK}"
      }
  ]
}
EOF
  fi
}
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4=$(curl -s4m6 ip.sb -k)
v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`
generate_config
generate_argo
generate_nezha
generate_pm2_file
[ -e nz.sh ] && bash nz.sh
[ -e argo.sh ] && bash argo.sh
[ -e ecosystem.config.js ] && pm2 start
