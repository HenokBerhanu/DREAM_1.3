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
~/DREAM_1.3/virtual-devices/ECG_monitor/ecg_monitor.py \
~/DREAM_1.3/virtual-devices/ECG_monitor/ecg-monitor.service \
vagrant@127.0.0.1:/home/vagrant/

# Move the scripts to the expected path inside the edge node
sudo mkdir -p /etc/kubeedge/devices/
sudo mv ecg_monitor.py /etc/kubeedge/devices/
sudo mv ecg-monitor.service /etc/systemd/system/

# Set permissions:
sudo chmod +x /etc/kubeedge/devices/ecg_monitor.py

# Reload and enable the systemd service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ecg-monitor.service

######################################################################################
############################################################################
# Verify it's running:
sudo systemctl status ecg-monitor
tail -f /var/log/syslog | grep ecg-monitor

# Restart the service if you update it
sudo systemctl restart ecg-monitor
sudo systemctl status ecg-monitor
       # Output
        ● ecg-monitor.service - Smart ECG Monitor Service
            Loaded: loaded (/etc/systemd/system/ecg-monitor.service; enabled; vendor preset: enabled)
            Active: active (running) since Mon 2025-04-21 19:55:49 UTC; 11s ago
        Main PID: 3810 (python3)
            Tasks: 1 (limit: 9477)
            Memory: 10.0M
                CPU: 45ms
            CGroup: /system.slice/ecg-monitor.service
                    └─3810 /usr/bin/python3 /etc/kubeedge/devices/ecg_monitor.py

        Apr 21 19:55:49 EdgeNode systemd[1]: Started Smart ECG Monitor Service.
        Apr 21 19:55:49 EdgeNode python3[3810]: /etc/kubeedge/devices/ecg_monitor.py:4: DeprecationWarning: Callback API version 1 is deprecated, update to latest version
        Apr 21 19:55:49 EdgeNode python3[3810]:   client = mqtt.Client()

#View logs from the service
sudo journalctl -u ecg-monitor.service -f
sudo journalctl -u ecg-monitor -f
    # Outputs:
        Sent: {'device_id': 'bed_sensor_01', 'timestamp': ..., 'occupancy': 1}

# Confirm it's running in the background
ps aux | grep ecg_monitor.py

# verify MQTT messages
sudo apt install -y mosquitto-clients
# You’ll see all messages your script is publishing in real time.
mosquitto_sub -t hospital/ecg_monitor -h localhost
        # Output: It is a JSON-formatted MQTT message published by the bed_sensor
        {"device_id": "bed_sensor_01", "timestamp": 1745105019, "occupancy": 1}
        {"device_id": "bed_sensor_01", "timestamp": 1745105024, "occupancy": 0}
        {"device_id": "bed_sensor_01", "timestamp": 1745105029, "occupancy": 0}
        
        # tthe time stam is a unix time format and can be converted to human readable like this from terminal, "date -d @1745105024
######################################################################################
#############################################################################







