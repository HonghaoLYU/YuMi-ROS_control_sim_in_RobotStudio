
%%socket communication with robotstudio
 
tc=tcpip('127.0.0.1',11002);
 
%open the communication 
 
fopen(tc);
fclose(tc);
% while true
%  
% %recive a message from the robotstudio
%  
%     message=fread(tc)
% end
 
%send a message to the robotstudio
 
% fwrite(tc,'12345678921234567');