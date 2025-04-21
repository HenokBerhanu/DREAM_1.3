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
~/DREAM_1.3/virtual-devices/infusion_pump/infusion_pump.py \
~/DREAM_1.3/virtual-devices/infusion_pump/infusion-pump.service \
vagrant@127.0.0.1:/home/vagrant/

# Move the scripts to the expected path inside the edge node
sudo mkdir -p /etc/kubeedge/devices/
sudo mv infusion_pump.py /etc/kubeedge/devices/
sudo mv infusion-pump.service /etc/systemd/system/

# Set permissions:
sudo chmod +x /etc/kubeedge/devices/infusion_pump.py

# Reload and enable the systemd service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now infusion-pump.service

######################################################################################
############################################################################
# Verify it's running:
sudo systemctl status infusion-pump
tail -f /var/log/syslog | grep infusion-pump

# Restart the service if you update it
sudo systemctl restart infusion-pump
sudo systemctl status infusion-pump
       # Output
        ● infusion-pump.service - Smart Infusion Pump Service
            Loaded: loaded (/etc/systemd/system/infusion-pump.service; enabled; vendor preset: enabled)
            Active: active (running) since Mon 2025-04-21 20:23:31 UTC; 18s ago
        Main PID: 4327 (python3)
            Tasks: 1 (limit: 9477)
            Memory: 10.0M
                CPU: 49ms
            CGroup: /system.slice/infusion-pump.service
                    └─4327 /usr/bin/python3 /etc/kubeedge/devices/infusion_pump.py

        Apr 21 20:23:31 EdgeNode systemd[1]: Started Smart Infusion Pump Service.
        Apr 21 20:23:31 EdgeNode python3[4327]: /etc/kubeedge/devices/infusion_pump.py:4: DeprecationWarning: Callback API version 1 is deprecated, update to latest version
        Apr 21 20:23:31 EdgeNode python3[4327]:   client = mqtt.Client()


#View logs from the service
sudo journalctl -u infusion-pump.service -f
sudo journalctl -u infusion-pump -f
    # Outputs:
        Sent: {'device_id': 'infusion_pump_03', 'timestamp': 1745267015, 'flow_rate': 86.57, 'status': 'running'}

# Confirm it's running in the background
ps aux | grep infusion_pump.py

# verify MQTT messages
sudo apt install -y mosquitto-clients
# You’ll see all messages your script is publishing in real time.
mosquitto_sub -t hospital/infusion_pump -h localhost
        # Output: It is a JSON-formatted MQTT message published by the bed_sensor
        {"device_id": "infusion_pump_02", "timestamp": 1745267073, "flow_rate": 20.81, "status": "running"}
        {"device_id": "infusion_pump_03", "timestamp": 1745267075, "flow_rate": 57.21, "status": "completed"}
        {"device_id": "infusion_pump_01", "timestamp": 1745267077, "flow_rate": 98.84, "status": "completed"}
        {"device_id": "infusion_pump_02", "timestamp": 1745267079, "flow_rate": 91.6, "status": "paused"}
        {"device_id": "infusion_pump_03", "timestamp": 1745267081, "flow_rate": 29.99, "status": "running"}

        
        # tthe time stam is a unix time format and can be converted to human readable like this from terminal, "date -d @1745105024
######################################################################################
#############################################################################







