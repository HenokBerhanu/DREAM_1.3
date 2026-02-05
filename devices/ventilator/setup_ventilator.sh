# Check 

# Check that a local mqtt broker is running
sudo netstat -tulnp | grep 1883
      # Output
      tcp        0      0 0.0.0.0:1883            0.0.0.0:*               LISTEN      1235/mosquitto      
      tcp6       0      0 :::1883                 :::*                    LISTEN      1235/mosquitto 

# label the EdgeNode to allow scheduling of edge workloads
kubectl label node edgenode kubeedge=true

# Then, in your pod YAMLs, use:
    nodeSelector:
       kubeedge: "true"

#####################################################
Deploy devices
#########################################################


#########################################################
# Inside the edge node
# Is a library imported inside the bed_sensor.py
# Missing dependency (paho-mqtt) issue
sudo apt update && sudo apt install -y python3-pip
sudo pip3 install paho-mqtt
##########################################################

# Coppy the required files from the host machine to the edge node
# Get ssh info from the edge core and get the private key directory
vagrant ssh-config EdgeNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/EdgeNode/virtualbox/private_key \
-P 2201 \
~/DREAM_1.3/virtual-devices/ventilator/ventilator.py \
~/DREAM_1.3/virtual-devices/ventilator/ventilator.service \
vagrant@127.0.0.1:/home/vagrant/

# Move the scripts to the expected path inside the edge node
sudo mkdir -p /etc/kubeedge/devices/
sudo mv ventilator.py /etc/kubeedge/devices/
sudo mv ventilator.service /etc/systemd/system/

# Set permissions:
sudo chmod +x /etc/kubeedge/devices/ventilator.py

# Reload and enable the systemd service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ventilator.service

######################################################################################
############################################################################
# Verify it's running:
sudo systemctl status ventilator
tail -f /var/log/syslog | grep ventilator

# Restart the service if you update it
sudo systemctl restart ventilator
sudo systemctl status ventilator
       # Output
        ● ventilator.service - Smart Ventilator Service
            Loaded: loaded (/etc/systemd/system/ventilator.service; enabled; vendor preset: enabled)
            Active: active (running) since Mon 2025-04-21 21:03:31 UTC; 1min 21s ago
        Main PID: 5020 (python3)
            Tasks: 1 (limit: 9477)
            Memory: 10.0M
                CPU: 58ms
            CGroup: /system.slice/ventilator.service
                    └─5020 /usr/bin/python3 /etc/kubeedge/devices/ventilator.py

        Apr 21 21:03:31 EdgeNode systemd[1]: Started Smart Ventilator Service.
        Apr 21 21:03:31 EdgeNode python3[5020]: /etc/kubeedge/devices/ventilator.py:4: DeprecationWarning: Callback API version 1 is deprecated, update to latest version
        Apr 21 21:03:31 EdgeNode python3[5020]:   client = mqtt.Client()



#View logs from the service
sudo journalctl -u ventilator.service -f
sudo journalctl -u ventilator -f
    # Outputs:
        Sent: {'device_id': 'ventilator_01', 'timestamp': 1745269417, 'respiratory_rate': 23, 'tidal_volume': 420.5, 'status': 'standby'}

# Confirm it's running in the background
ps aux | grep ventilator.py

# verify MQTT messages
sudo apt install -y mosquitto-clients
# You’ll see all messages your script is publishing in real time.
mosquitto_sub -t hospital/ventilator -h localhost
        # Output: It is a JSON-formatted MQTT message published by the bed_sensor
        {"device_id": "ventilator_03", "timestamp": 1745269649, "respiratory_rate": 25, "tidal_volume": 444.4, "status": "standby"}
        {"device_id": "ventilator_01", "timestamp": 1745269651, "respiratory_rate": 19, "tidal_volume": 389.2, "status": "operational"}
        {"device_id": "ventilator_02", "timestamp": 1745269653, "respiratory_rate": 20, "tidal_volume": 352.4, "status": "operational"}


        
        # tthe time stam is a unix time format and can be converted to human readable like this from terminal, "date -d @1745105024
######################################################################################
#############################################################################







