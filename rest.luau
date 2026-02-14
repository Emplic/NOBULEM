if not LPH_OBFUSCATED then
getgenv().LPH_NO_VIRTUALIZE=function(a)return a end
getgenv().LPH_JIT=function(a)return a end
end

local a=cloneref or function(a)return a end

local b=a(game:GetService"ReplicatedStorage")
local c=a(game:GetService"HttpService")
a(game:GetService"Players")

local d=loadstring(game:HttpGet"https://raw.githubusercontent.com/laagginq/ui-libraries/main/xaxas-notification/src.lua")();
local e=d.new{
NotificationLifetime=3,
NotificationPosition="Middle",
TextFont=Enum.Font.Code,
TextColor=Color3.fromRGB(255,255,255),
TextSize=15,
TextStrokeTransparency=0,
TextStrokeColor=Color3.fromRGB(0,0,0)
};
e:BuildNotificationUI();
e:Notify"Initializing Nobulem...";

local f={
{
Name="Hypershot",
ScriptId="05120379223359915853",
CheckFunction=function()
return b:FindFirstChild"Weapons"~=nil
end
},
{
Name="Flick",
ScriptId="10454517847790247851",
CheckFunction=function()
return b:FindFirstChild'ModuleScripts'~=nil
end
},
{
Name="Realm Rampage",
ScriptId="76386821174283751255",
CheckFunction=function()
return b:FindFirstChild"Replicate"~=nil
end
},
{
Name="Basketball Arcade",
ScriptId="82821932812279873779",
CheckFunction=function()
local f=b:FindFirstChild"Zone"
return f and f:FindFirstChild"RotatedRegion3"~=nil
end
},
{
Name="Midnight Chasers: Highway Racing",
ScriptId="11933192791628534715",
CheckFunction=function()
return b:FindFirstChild"NitrousVFX"~=nil
end
},
{
Name="War Tycoon",
ScriptId="47810414497836905461",
CheckFunction=function()
return b:FindFirstChild"ACS_Engine"~=nil
end
},
{
Name="Marvellous Smackdown",
ScriptId="84770629132565768307",
CheckFunction=function()
return b:FindFirstChild"SelectACharacter"~=nil
end
},
{
Name="Bulked up",
ScriptId="75606579830270260942",
CheckFunction=function()
return workspace:FindFirstChild"Laser Fence"~=nil
end
},
{
Name="Slipshot",
ScriptId="45071982026652889788",
CheckFunction=function()
return game:GetService"StarterPlayer":FindFirstChild'BetterReplicationClient'~=nil
end
}
}

local function detectGame()
for g,h in ipairs(f)do
local i,j=pcall(h.CheckFunction)
if i and j then
return h
end
end
return nil
end

local function init()
local g=detectGame()

if not g then
return
end

e:Notify("Loading "..g.Name.."...")

local h=getgenv().script_key or"0668dd12175cd3d6d1c201ae"
local i=g.ScriptId
local j={"eu-1","us-1"}


local k=(request or http_request or(http and http.request)or(syn and syn.request))
if not k then
return
end

local l

for m,n in ipairs(j)do
local o="https://"..n..".luaprot.net/api/v1/nodes/get"

local p,q=pcall(function()
return k{Url=o,Method="GET"}
end)

if p and q and q.StatusCode==200 then
local r=c:JSONDecode(q.Body)
if r and r.node then
l=r.node
break
end
end
end

if not l then
return
end

getgenv().LP_NODE=l
getgenv().lp_key=h

local m="https://"..l..".luaprot.net/api/v1/loader/get/"..i.."/"..h local

n=pcall(function()
return loadstring(game:HttpGet(m))()
end)

if n then
e:Notify"Successfully Loaded!"
end
end

init()
