adduser --disabled-password --gecos "" ${user_name}
usermod -a -G sudo ${user_name}
mkdir -p /home/${user_name}/.ssh
echo "${user_publickey }" >> /home/${user_name}/.ssh/authorized_keys > /dev/null
chown -R ${user_name}:${user_name} /home/${user_name}/.ssh
chmod -R go-rx /home/${user_name}/.ssh