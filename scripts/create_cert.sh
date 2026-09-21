#!/bin/bash
# 创建固定的本地开发证书「WipeShield Dev」（一次性操作）。
# 用途：让 WipeShield.app 的代码签名身份在重新构建之间保持稳定，
#       使 macOS 辅助功能等 TCC 授权不会因每次 rebuild 而失效。
# 证书保存在登录钥匙串；删除它并重新运行本脚本可重建（重建后需重新授权一次）。
set -euo pipefail

CERT_CN="WipeShield Dev"

if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CERT_CN"; then
    echo "证书「$CERT_CN」已存在，无需创建。"
    security find-identity -v -p codesigning | grep -F "$CERT_CN"
    exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/cert.cnf" <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3_req
prompt = no
[dn]
CN = WipeShield Dev
O = WipeShield
OU = Development
[v3_req]
keyUsage = critical, digitalSignature
extendedKeyUsage = codeSigning
basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
EOF

# 临时打包密码：仅保护 mktemp 目录里的一次性 .p12（导入钥匙串后即删除），随机生成、不留明文。
P12_PASS="$(openssl rand -hex 16)"

# 注意：macOS 的 security 工具只认传统 PKCS#12 加密（3DES/SHA1），
# 新版 OpenSSL/LibreSSL 默认的 AES-256 导出会导致导入报 MAC 校验失败。
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" -config "$WORK/cert.cnf" 2>/dev/null
openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" -name "$CERT_CN" \
    -out "$WORK/wipeshield-dev.p12" -passout "pass:$P12_PASS" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

security import "$WORK/wipeshield-dev.p12" \
    -k "$HOME/Library/Keychains/login.keychain-db" -P "$P12_PASS" -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -p basic "$WORK/cert.pem"

echo "证书已创建并受信任："
security find-identity -v -p codesigning | grep -F "$CERT_CN"
