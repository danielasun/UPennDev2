local mot={};
mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,};
mot.keyframes={  

{
angles=vector.new({
0,-39,
236,5,-147,
0,0,-90,106,-35,0,
0,0,-90,106,-35,1,
237,-5,-147
})*math.pi/180,
duration = 0.3;
},

{
angles=vector.new({
0,-39,
236,5,-88,
0,0,-88,106,-35,0,
0,0,-88,106,-35,0,
236,-5,-88
})*math.pi/180,
duration = 0.4;
},

{
angles=vector.new({
0,-39,
226,25,-37,
0,0,30,58,0,0,
0,0,30,58,0,0,
226,-25,-37
})*math.pi/180,
duration = 0.6;
},

{
angles=vector.new({
0,-39,
178,6,-17,
0,0,33,109,-80,0,
0,0,33,109,-80,0,
178,-6,-17
})*math.pi/180,
duration = 0.5;
},

{
angles=vector.new({
0,-39,
60,14,-9,
0,0,33,94,-80,0,
0,0,33,94,-80,0,
60,-14,-9
})*math.pi/180,
duration = 0.6;
},

--SJ: This is final pose of bodySit
 
{
angles=vector.new({
0,0,
105,29,-45,
0,3,-35,110,-75,-3,
0,-3,-35,110,-75,3,
105,-29,-45
})*math.pi/180,
duration = 0.5;
},

};

return mot;