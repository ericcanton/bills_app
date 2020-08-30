# bills_app
Shiny app for managing monthly bills
---  
This simple Shiny app is designed to make managing one's monthly bills simpler. Upcoming bills are displayed in order, based on reading the `usual.csv` database. A ledger of paid bills is also displayed, being read from `ledger.csv`.  At a minimum, to run this app you need to have a modern-ish version of R installed, along with the `shiny`, `shinyWidgets`, `data.table`, `DT`, and `lubridate` packages. 

There is a "Bill Management" widget that allows the user to create a new recurring bill (to be shown under "Upcoming Bills") and to pay a bill (updating the ledger). Depending on if a bill is created or paid, a line is added to the appropriate csv database.  
- TODO: Add functionality to delete and modify bills from within the app.  

Since the databases are csv files, it is easy to edit either by hand in a text editor or spreadsheet program. If you create/pay bills within the app, Shiny should reflect the changes immediately. If you edited the databases by hand, refreshing the Shiny app page will reflect changes.  

---
## Running the app  
This section describes one way to serve this app to your local network; be careful doing this in public places, because anyone on your network can modify the csv files using this app! If you already know how to run Shiny apps and are happy with your method, there's nothing unusual you need to do to get `bills_app` running. Just be sure to have `usual.csv` and `ledger.csv` in the same folder as `app.R`, or modify the `usual_bills_csv` and `paid_bills_ledger` variables in `app.R` to point to where yo have these saved.  

1. Install R (https://www.r-project.org/). Most newer versions should be okay; tested using 4.0.2. Then, install the needed packages using the following command in a running R console:
```R
> install.packages("shiny", "shinyWidgets", "data.table", "DT", "lubridate")
```

2. Find your computer's router IP address. If you're running a modern Debian-based Linux (e.g. Debian, Ubuntu), you can do this via the `ip address` command.
On Mac and some other Unixes, try `ifconfig`. These commands will give an output listing your network interfaces and their configurations. The `lo` interface is your `localhost` (IP address `127.0.0.1`), but your router IP will be some other interface later in the list. For example, you might see `eno1` for an ethernet connection to your router, or `wlp2s0` for a wireless connection. Supposing we are connected via ethernet, we are looking for something like:
```bash
4: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 44:39:c4:54:b9:1a brd ff:ff:ff:ff:ff:ff
    altname enp0s25
    inet 192.168.0.123/24 brd 192.168.0.255 scope global dynamic noprefixroute eno1
       valid_lft 52089sec preferred_lft 52089sec
    inet6 fe80::4639:c4ff:fe54:b91a/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```
The `inet 192.168.0.123/24` line is what we're looking for, and tells us our machine's router IP is `192.168.0.123`.

3. From a running R console (maybe the one from step 1) navigate to the `bills_app` directory (containing `app.R`) using `setwd("path/to/bills_app")`, then start the Shiny app on our router IP address and port 2000 using:
```R
runApp(host = "192.168.0.123", port=2000)
```
You can use a different port, so long as it is at least 1024, and doesn't conflict with other running apps you may be serving from this computer (like a Jupyter server). If you'd like to only be able to view the app from the computer running the app, use `host = "127.0.0.1"`.

4. Navigate to the running app in your browser at `http://192.168.0.123:2000` from any device connected to your router, like a phone/tablet or laptop.
