# YuMi-ROS_control_sim_in_RobotStudio
A interface for controling yumi simulated in RobotStudio (RS) through ROS.
If you don't have a real yumi robot, now you can sim it in the RobotStudio, and the most important is that a interface between  
the ROS and RS is provides in this repo.

#### Author: Honghao Lv
#### Email:lvhonghao@zju.edu.cn
#### Date-Version: 2019.9.6 V0.1

## Demo:


## You can config this in your own PC follow the below steps:
1. Clone this repo in your Windows PC, and creat a solution or station in your RS.
Ps: You can load the rapid scripts through "Restore from System Backup". The system backup is in
You also can config the rapid script though the independent rapid module documents in
2. If you want to use ROS to control the configed YuMi in RS, you need to clone the another repo of mine.
3. Config the repo of Yumi_ws in anothor PC or Vitual Machine (another independent PC installed ubuntu is better).
4. Connect the two PC with one network cable if you use two PC and config the IP4 static adress of PC with RS to 192.168.0.1, and also  
config the IP4 static adress of Ubuntu PC with ROS to 192.168.0.4.
PS: you need to shutdown the firewall of windows.
5. start and run the sim yumi in RS, run the launch file in ubuntu: 
5.1 roslaunch robot_interface_nogrippers.launch
5.2 roslaunch yumi_moveit_config moveit_planning_excuation_nogrippers.launch rviz:=true
6. enjoy it.
