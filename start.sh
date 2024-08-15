#!/usr/bin/env sh

echo 'Starting up...'

# error: adding [-i tailscale0 -j MARK --set-mark 0x40000] in v4/filter/ts-forward: running [/sbin/iptables -t filter -A ts-forward -i tailscale0 -j MARK --set-mark 0x40000 --wait]: exit status 2: iptables v1.8.6 (legacy): unknown option "--set-mark"
modprobe xt_mark

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
#echo 'net.ipv6.conf.all.disable_policy = 1' | tee -a /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

/app/tailscaled --verbose=1 --port 41641 --socks5-server=localhost:3215 --tun=userspace-networking &
sleep 5
if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
    echo "tailscaled.sock does not exist. exit!"
    exit 1
fi

until /app/tailscale up \
    --authkey=${TAILSCALE_AUTH_KEY} \
    --hostname=ntrance-${FLY_REGION} \
    --advertise-exit-node \
    --ssh
do
    sleep 0.1
done

echo 'Tailscale started'

echo 'Starting Squid...'

#squid &

echo 'Squid started'

echo 'Starting Dante...'

#sockd &

echo 'Dante started'

echo 'Starting dnsmasq...'

#dnsmasq &

echo 'dnsmasq started'

sleep infinity
