# keepalived-nginx
keepalived+nginx

### 关于邮件通知
   
配置文件追加信息（/etc/mail.rc）   
vim /etc/mail.rc   
#发件人信息   
set from=xxxxxx@163.com    #发件人邮箱地址(163设置得开起允许代理)   
set smtp=smtp.163.com    #smtp地址   
set smtp-auth-user=xxxxxx@163.com  #邮箱用户名，不用加域名   
set smtp-auth-password=******   #邮箱密码（邮件密码是smtp代理授权码）   
set smtp-auth=login   #邮箱验证方式   
   
#测试发送   
echo "hello world" | mail -s "hello" xxxxxx@163.com   
