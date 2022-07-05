Script that will replace the certificates on UAG and Horizon Connection server with signed certificates from LetsEncrypt.
This script uses Loopia plugin since thats where i had my domain registered, but script can easily be modified to work with multiple providers. https://poshac.me/docs/v4/Plugins/
Since most UAGs and HCS work in pairs, run this script on each pair using Windows Scheduler, don't forget to run it as a user which has Admin priviliges.
