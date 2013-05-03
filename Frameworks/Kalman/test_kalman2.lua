local torch = require 'torch'
torch.Tensor = torch.DoubleTensor
local kalman1 = require 'libKalman'
local show_kalman_gain = true

-- 2 dimensional kalman filter
local myDim = 2;
local x,P = kalman1:init_position_filter( myDim )
local str = ''
for d=1,x:size(1) do
	str = str..' '..x[d]
end
print('Initial:',str)

for i=1,5 do
	-- One Kalman
	x,P = kalman1:predict()
	local prior_str = 'Prior:\t'
	for d=1,x:size(1) do
		prior_str = prior_str..string.format(' %f',x[d])
	end
	local obs = torch.Tensor(myDim):zero()
	obs[1] = (i-1)/30
	local observation_str = 'Observe:\t'
	for d=1,obs:size(1) do
		observation_str = observation_str..string.format(' %f',obs[d])
	end
	x,P,K = kalman1:correct( obs )
	local state_str = 'State:\t'
	for d=1,x:size(1) do
		state_str = state_str..string.format(' %f',x[d])
	end
	-- Debug the Gain
	local kgain_str = ''
	if show_kalman_gain then
		kgain_str = 'Kalman gain\n'
		for i=1,K:size(1) do
			for j=1,K:size(2) do
				kgain_str = kgain_str..string.format('   %.2f',K[i][j])
			end
			kgain_str = kgain_str..'\n'
		end
	end
	-- End Debug of gain
	
	print('Observation',i)
	print(prior_str)
	print(observation_str)
	print(state_str)
	print(kgain_str)
	
end