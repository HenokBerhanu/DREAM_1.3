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
~/DREAM_1.3/virtual-devices/bed_sensor/bed_sensor.py \
~/DREAM_1.3/virtual-devices/bed_sensor/bed-sensor.service \
vagrant@127.0.0.1:/home/vagrant/

# Move the scripts to the expected path inside the edge node
sudo mkdir -p /etc/kubeedge/devices/
sudo mv bed_sensor.py /etc/kubeedge/devices/
sudo mv bed-sensor.service /etc/systemd/system/

# Set permissions:
sudo chmod +x /etc/kubeedge/devices/bed_sensor.py

# Reload and enable the systemd service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now bed-sensor.service

######################################################################################
############################################################################
# Verify it's running:
sudo systemctl status bed-sensor
tail -f /var/log/syslog | grep bed_sensor

# Restart the service if you update it
sudo systemctl restart bed-sensor
sudo systemctl status bed-sensor
       # Output
        ● bed-sensor.service - Smart Bed Sensor Service
            Loaded: loaded (/etc/systemd/system/bed-sensor.service; enabled; vendor preset: enabled)
            Active: active (running) since Sat 2025-04-19 23:01:20 UTC; 18ms ago
        Main PID: 9838 (python3)
            Tasks: 1 (limit: 9477)
            Memory: 2.9M
                CPU: 16ms
            CGroup: /system.slice/bed-sensor.service
                    └─9838 /usr/bin/python3 /etc/kubeedge/devices/bed_sensor.py

        Apr 19 23:01:20 EdgeNode systemd[1]: Started Smart Bed Sensor Service.

#View logs from the service
sudo journalctl -u bed-sensor.service -f
sudo journalctl -u bed-sensor -f
    # Outputs:
        Sent: {'device_id': 'bed_sensor_01', 'timestamp': ..., 'occupancy': 1}

# Confirm it's running in the background
ps aux | grep bed_sensor.py

# verify MQTT messages
sudo apt install -y mosquitto-clients
# You’ll see all messages your script is publishing in real time.
mosquitto_sub -t hospital/bed_sensor -h localhost
        # Output: It is a JSON-formatted MQTT message published by the bed_sensor
        {"device_id": "bed_sensor_01", "timestamp": 1745105019, "occupancy": 1}
        {"device_id": "bed_sensor_01", "timestamp": 1745105024, "occupancy": 0}
        {"device_id": "bed_sensor_01", "timestamp": 1745105029, "occupancy": 0}
        
        # tthe time stam is a unix time format and can be converted to human readable like this from terminal, "date -d @1745105024
######################################################################################
#############################################################################







