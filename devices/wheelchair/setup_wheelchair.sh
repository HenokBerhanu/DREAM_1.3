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
~/DREAM_1.3/virtual-devices/wheelchair/wheelchair.py \
~/DREAM_1.3/virtual-devices/wheelchair/wheelchair.service \
vagrant@127.0.0.1:/home/vagrant/

# Move the scripts to the expected path inside the edge node
sudo mkdir -p /etc/kubeedge/devices/
sudo mv wheelchair.py /etc/kubeedge/devices/
sudo mv wheelchair.service /etc/systemd/system/

# Set permissions:
sudo chmod +x /etc/kubeedge/devices/wheelchair.py

# Reload and enable the systemd service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now wheelchair.service

######################################################################################
############################################################################
# Verify it's running:
sudo systemctl status wheelchair
tail -f /var/log/syslog | grep wheelchair

# Restart the service if you update it
sudo systemctl restart wheelchair
sudo systemctl status wheelchair
       # Output
        ● wheelchair.service - Smart Wheelchair Service
            Loaded: loaded (/etc/systemd/system/wheelchair.service; enabled; vendor preset: enabled)
            Active: active (running) since Mon 2025-04-21 21:25:22 UTC; 16s ago
        Main PID: 5350 (python3)
            Tasks: 1 (limit: 9477)
            Memory: 10.0M
                CPU: 48ms
            CGroup: /system.slice/wheelchair.service
                    └─5350 /usr/bin/python3 /etc/kubeedge/devices/wheelchair.py

        Apr 21 21:25:22 EdgeNode systemd[1]: Started Smart Wheelchair Service.
        Apr 21 21:25:23 EdgeNode python3[5350]: /etc/kubeedge/devices/wheelchair.py:4: DeprecationWarning: Callback API version 1 is deprecated, update to latest version
        Apr 21 21:25:23 EdgeNode python3[5350]:   client = mqtt.Client()



#View logs from the service
sudo journalctl -u wheelchair.service -f
sudo journalctl -u wheelchair -f
    # Outputs:
        Sent: {'device_id': 'wheelchair_03', 'timestamp': 1745270793, 'location': {'room': 118, 'floor': 2}, 'battery_level': 88, 'status': 'charging'}

# Confirm it's running in the background
ps aux | grep wheelchair.py

# verify MQTT messages
sudo apt install -y mosquitto-clients
# You’ll see all messages your script is publishing in real time.
mosquitto_sub -t hospital/wheelchair -h localhost
        # Output: It is a JSON-formatted MQTT message published by the bed_sensor
        {"device_id": "wheelchair_01", "timestamp": 1745270879, "location": {"room": 100, "floor": 5}, "battery_level": 35, "status": "in-use"}
        {"device_id": "wheelchair_02", "timestamp": 1745270881, "location": {"room": 106, "floor": 2}, "battery_level": 94, "status": "idle"}
        {"device_id": "wheelchair_03", "timestamp": 1745270883, "location": {"room": 117, "floor": 4}, "battery_level": 20, "status": "in-use"}


        
        # tthe time stam is a unix time format and can be converted to human readable like this from terminal, "date -d @1745105024
######################################################################################
#############################################################################







