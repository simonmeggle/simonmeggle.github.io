---
title:  Installing <em>Archlinux</em> <br/> on Raspberry Pi
---

Is it still necessary to present it? The Raspberry Pi is a nano-computer which, due to its small size, low power consumption and very low cost[[about 35 € in its most powerful version, to which must be added an SD card, μUSB  and ethernet cables, less than € 50 in total]], makes an essential personal server or hack tool.

Despite its limited computing power, it is perfectly possible to make a web server, a personal cloud, a NAS, an *Airplay* terminal, a retro games console... or all at once. Whatever your goal, it is necessary to install a Linux distribution.

We will see how to install and configure Archlinux on our Raspberry Pi, directly from the command line by the network, which means that we will have no need of keyboard or screen.

So for this tutorial, you'll only need:

* a _Raspberry Pi_, model B ;
* a _SD card_ with at least 2 GB to install our system;
* an _µUSB cable_ to put our Raspberry Pi powered;
* an _ethernet cable_ to connect our Pi to our router.

![Raspberry Pi – Jonathan Rutheiser, CC BY-SA 3.0](/medias/raspberry/raspberrypi.svg)

## Installing *Archlinux*
Among the many distributions available for Raspberry Pi, we will use *[ArchLinux](http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/)*, due to its lightness and comprehensive ecosystem that has been built around it.

### Downloading

Start by retrieving the latest version of *Archlinux*. An [image](http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/ArchLinuxARM-2014.06-rpi.img.zip) is offered on the Raspberry Pi site[[at the time of writing this article, the last image has been published in this format on June 2014; however, we will update the system once it is installed]]. Download it, and then extract it:

```bash
curl -OL http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/ArchLinuxARM-2014.06-rpi.img.zip
unzip ArchLinuxARM-2014.06-rpi.img.zip
```

### Installing
We will write the previously downloaded image to the SD card. To do this, insert into our computer the SD card that will host the system.

It is necessary for us to know the path to the SD card. On OS X, you can use in the terminal the following command to get the ID of your SD card (`/dev/disk2` in the following example):

```bash
diskutil list
```

We now write the image to the card. Warning, the entire contents of the SD card will be lost! For this, we enter the following commands (where `/dev/disk2`[[on OS X, we use `rdisk2` instead of `disk2` in order to make the copy faster]] is the path to the SD card):


```bash
diskutil unmountDisk /dev/disk2
sudo dd if=ArchLinuxARM-2014.06-rpi.img of=/dev/rdisk2 bs=1m
sudo diskutil eject /dev/disk2
```


We can then eject the SD card and insert it into your Raspberry Pi. Connect it to our network, and then put it on.

## Connecting to the Raspberry Pi
We will access our Raspberry Pi from our computer, using SSH. Users of OS X or Linux can directly launch `ssh`, while those of Windows prefer to use a program like [*PuTTY*](http://www.putty.org/). Otherwise, it is possible to connect a USB keyboard and connect the Raspberry Pi to a monitor using its HDMI port.

Like any computer, the Raspberry Pi is identified on the network by its IP address. For us to connect, it is necessary to know it.

Two options are available:

* you want to access it from your local network, and in this case it suffices to know what IP your router assigns;
* you want to be able to access it anywhere[[for instance, this will be the case for a web server]], and in this case your router must redirect external requests to your Raspberry Pi.


### From the local network
After connecting to your router and then turned our Raspberry Pi, we need to know its IP address[[under OS X, use `arp -a`]].

For more comfort, go on your router admin interface and ask to assign a fixed IP address. Thus, it will always be the same if your router or Raspberry restart.

Once the address of the Raspberry Pi known (we will use `192.168.1.1` in the following example), we can connect via SSH to our Raspberry Pi with the command:

```bash
ssh root@192.168.1.1
```

Then validate the security certificate, and enter the default password `root`. Here we are connected to our Raspberry Pi!


### From anywhere
In many cases, we want our Raspberry Pi accessible from outside our network. Your router must have a fixed IP; otherwise, it is necessary to use a dynamic DNS client.

For this, the approach depends largely on the model of your router or box: connect to the administration interface and begin to assign a fixed IP to your Raspberry Pi. Then, tell the router to always transfer to this IP address the desired ports: in particular, port 22 for SSH[[if you want to configure a web server later, you can do the same with ports 80 and 443]].

Once this is achieved, we can now connect from anywhere on internal (where `80.23.170.17` is the external IP of our network):

```bash
ssh root@80.23.170.17
```

We can also assign a domain name to our Raspberry (especially if it will serve as a web server). At your registar, create an `A` field for your `domain.tld` in which you specify the external IP address (`80.23.170.17` in our example). Once committed changes, we can access our Pi with:

```bash
ssh pi@domain.tld
```

Then validate the security certificate, and enter the default password `raspberry`. Here we are connected to our Raspberry Pi!

## Configuring *Archlinux*

### Creating users

First, let's change the administrator password:

```bash
passwd root
```

We can also take the opportunity to create an user account, to whom we can give `sudo` rights:

```bash
useradd -m -g users -G wheel -s /bin/bash pi
passwd pi
pacman -S sudo
```

### Updating *Arch*

To update the entire[[this command will update your software as well as the drivers required to Raspberry Pi]] system, we simply use the following command:

```bash
pacman -Suy
```


### Language

By default, the system is configured in English. In order to obtain an interface in another language, modify the following file:

```bash
nano /etc/locale.gen
```

For French, simply uncomment the line `fr_FR.UTF-8`. The we regenerate *locales* with:

```bash
locale-gen
```

Then select the default locale by editing the following file:

```bash
nano /etc/locale.conf
```

To this is added the following content:

```
LANG="fr_FR.UTF-8"
LANGUAGE="fr_FR:en_US"
LC_COLLATE=C
```

Upon restart, then the terminal will be in the right language.

### Miscellaneous

*Archlinux* use the `vi` text editor, which I prefer `nano` for its simplicity. To change this default, we use:

```bash
pacman -Rns vi
ln -s /usr/bin/nano /usr/bin/vi
```

It is also possible to rename the machine name that appears in the terminal. For example:

```bash
hostname raspberry
```


### Improving safety
Our Raspberry Pi being connected to a network, it will be subject to many attacks. To minimize the risk, it is first possible to change the default port for SSH (22) at any port. To do this, edit the following file:

```bash
nano /etc/ssh/sshd_config
```

Change the `Port 22` line by remplacing `22` with the wanted number (for instance, `50132`). You can then connect via SSH, indicating the parameter `-p 50132`:

```bash
ssh pi@80.23.170.17 -p 50132
```

Moreover, the `fail2ban` package helps prevent dictionary attacks or bruteforce reading the connection logs and blocking repeated attempts connection with a user name or bad password. Simply install the package:

```bash
pacman -S fail2ban
```

You can regularly monitor the logs to identify fraudulent attempts connection with the command `grep 'sshd' /var/log/auth.log`.

## Conclusion
You now have a fully functional machine accessible from your network or from the Internet. If its computing power is limited, however, it is possible to use it in many ways:

- web server;
- personal cloud;
- RSS feed manager;
- torrent downloads manager;
- NAS;
- *Airplay* terminal;
- Retro games console...


