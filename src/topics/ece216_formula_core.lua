-- ECE 216 formula-sheet numerical workspaces.
-- Keep top-level locals minimal to avoid Luna local-variable limits.

ECE216Core = ECE216Core or {}
ECE216Core.eps0 = 8.854187817e-12
ECE216Core.mu0 = 4*math.pi*1e-7
ECE216Core.c0 = 299792458

function ECE216Core.registerParallelPlate(calculators)
    calculators.topicParallelPlateLine=Calculator.new({
        id="topicParallelPlateLine",title="Parallel-Plate Line Design",
        subtitle="Formula-sheet R', L', G', C', Z0 and gamma",
        inputs={
            {label="Plate width w",unit="m"},{label="Dielectric thickness h",unit="m"},
            {label="Relative permittivity er"},{label="Relative permeability mur"},
            {label="Dielectric conductivity sigma",unit="S/m"},{label="Conductor conductivity sigmac",unit="S/m"},
            {label="Frequency f",unit="Hz"}
        },
        outputs={
            {label="R'",unit="ohm/m"},{label="L'",unit="H/m"},{label="G'",unit="S/m"},{label="C'",unit="F/m"},
            {label="Z0 real",unit="ohm"},{label="Z0 imag",unit="ohm"},{label="|Z0|",unit="ohm"},
            {label="alpha",unit="Np/m"},{label="beta",unit="rad/m"},{label="up/c"}
        },
        allowOptionalInputs=true,minimumInputs=4,visibleInputCount=5,
        calculate=function(v)
            local w,h,er,mur,sig,sigc,f=v[1],v[2],v[3],v[4] or 1,v[5] or 0,v[6],v[7]
            if not(w and h and er and f) then error("Enter w, h, er, and f") end
            if w<=0 or h<=0 or er<=0 or mur<=0 or f<=0 then error("Invalid positive input") end
            local mu=ECE216Core.mu0*mur
            local eps=ECE216Core.eps0*er
            local R=0
            if sigc and sigc>0 then
                local Rs=math.sqrt(math.pi*f*mu/sigc)
                R=2*Rs/w
            end
            local L=mu*h/w
            local G=sig*w/h
            local C=eps*w/h
            local omega=2*math.pi*f
            local nr,ni=R,omega*L
            local dr,di=G,omega*C
            local dd=dr*dr+di*di
            local rr=(nr*dr+ni*di)/dd
            local ri=(ni*dr-nr*di)/dd
            local rm=math.sqrt(rr*rr+ri*ri)
            local zr=math.sqrt(math.max(0,(rm+rr)/2))
            local zi=math.sqrt(math.max(0,(rm-rr)/2)); if ri<0 then zi=-zi end
            local pr=nr*dr-ni*di
            local pi=nr*di+ni*dr
            local pm=math.sqrt(pr*pr+pi*pi)
            local alpha=math.sqrt(math.max(0,(pm+pr)/2))
            local beta=math.sqrt(math.max(0,(pm-pr)/2)); if pi<0 then beta=-beta end
            beta=math.abs(beta)
            return R,L,G,C,zr,zi,math.sqrt(zr*zr+zi*zi),math.abs(alpha),beta,(omega/beta)/ECE216Core.c0
        end
    })
end

function ECE216Core.registerStub(calculators)
    calculators.topicStub=Calculator.new({
        id="topicStub",title="Open / Short Stub",
        subtitle="Lossless transmission-line stub input impedance",
        inputs={{label="Characteristic Z0",unit="ohm"},{label="beta",unit="rad/m"},{label="Length l",unit="m"}},
        outputs={{label="Open stub reactance",unit="ohm"},{label="Short stub reactance",unit="ohm"}},
        calculate=function(v)
            local z0,beta,l=v[1],v[2],v[3]
            if z0<=0 or beta<=0 or l<0 then error("Invalid Z0, beta, or length") end
            local x=beta*l
            local t=math.tan(x)
            if math.abs(t)<1e-14 then return -1e99,0 end
            return -z0/t,z0*t
        end
    })
end

function ECE216Core.registerChargeRelax(calculators)
    calculators.topicChargeRelax=Calculator.new({
        id="topicChargeRelax",title="Charge Relaxation",
        subtitle="rho(t)=rho0 exp[-(sigma/epsilon)t]",
        inputs={{label="Initial charge density rho0"},{label="Conductivity sigma",unit="S/m"},{label="Relative permittivity er"},{label="Time t",unit="s"},{label="Charge density rho(t)"}},
        outputs={{label="Relaxation time tau",unit="s"},{label="rho(t)"},{label="Time from rho/rho0",unit="s"}},
        allowOptionalInputs=true,minimumInputs=3,
        calculate=function(v)
            local rho0,sigma,er,t,rho=v[1],v[2],v[3],v[4],v[5]
            if not(sigma and er) or sigma<=0 or er<=0 then error("Enter positive sigma and er") end
            local tau=ECE216Core.eps0*er/sigma
            local rhot=0/0
            if rho0 and t then rhot=rho0*math.exp(-t/tau) end
            local ts=0/0
            if rho0 and rho and rho0~=0 and rho/rho0>0 then ts=-tau*math.log(rho/rho0) end
            return tau,rhot,ts
        end
    })
end

function ECE216Core.registerTransformer(calculators)
    calculators.topicIdealTransformer=Calculator.new({
        id="topicIdealTransformer",title="Ideal Transformer Ratios",
        subtitle="V1/V2 = I2/I1 = N1/N2",
        inputs={{label="V1",unit="V"},{label="V2",unit="V"},{label="I1",unit="A"},{label="I2",unit="A"},{label="N1"},{label="N2"}},
        outputs={{label="Turns ratio N1/N2"},{label="Voltage ratio V1/V2"},{label="Current ratio I2/I1"}},
        allowOptionalInputs=true,minimumInputs=2,
        calculate=function(v)
            local ratio=nil
            if v[5] and v[6] and v[6]~=0 then ratio=v[5]/v[6] end
            if not ratio and v[1] and v[2] and v[2]~=0 then ratio=v[1]/v[2] end
            if not ratio and v[4] and v[3] and v[3]~=0 then ratio=v[4]/v[3] end
            if not ratio then error("Enter one complete ratio pair") end
            return ratio,ratio,ratio
        end
    })
end

function ECE216Core.registerPoynting(calculators)
    calculators.topicPoynting=Calculator.new({
        id="topicPoynting",title="Poynting Vector",
        subtitle="S = E x H",
        inputs={{label="Ex"},{label="Ey"},{label="Ez"},{label="Hx"},{label="Hy"},{label="Hz"}},
        outputs={{label="Sx",unit="W/m^2"},{label="Sy",unit="W/m^2"},{label="Sz",unit="W/m^2"},{label="|S|",unit="W/m^2"}},
        calculate=function(v)
            local sx=v[2]*v[6]-v[3]*v[5]
            local sy=v[3]*v[4]-v[1]*v[6]
            local sz=v[1]*v[5]-v[2]*v[4]
            return sx,sy,sz,math.sqrt(sx*sx+sy*sy+sz*sz)
        end
    })
end

function ECE216Core.registerMagnetostatics(calculators)
    calculators.topicMagnetostatics=Calculator.new({
        id="topicMagnetostatics",title="Magnetostatics Basics",
        subtitle="Long wire, solenoid, force, torque, magnetic energy",
        inputs={{label="Current I",unit="A"},{label="Radius/distance r",unit="m"},{label="Relative permeability mur"},{label="Turns N"},{label="Solenoid length l",unit="m"},{label="Wire segment length",unit="m"},{label="B field",unit="T"},{label="Angle",unit="degrees"},{label="Loop area A",unit="m^2"},{label="Inductance L",unit="H"}},
        outputs={{label="B long wire",unit="T"},{label="B solenoid",unit="T"},{label="Wire force magnitude",unit="N"},{label="Magnetic torque",unit="N*m"},{label="Magnetic energy",unit="J"}},
        allowOptionalInputs=true,minimumInputs=2,visibleInputCount=5,
        calculate=function(v)
            local I,r,mur,N,l,seg,B,deg,A,L=v[1],v[2],v[3] or 1,v[4],v[5],v[6],v[7],v[8] or 90,v[9],v[10]
            local mu=ECE216Core.mu0*mur
            local blong=0/0; if I and r and r>0 then blong=mu*I/(2*math.pi*r) end
            local bsol=0/0; if I and N and l and l>0 then bsol=mu*N*I/l end
            local s=math.sin(deg*math.pi/180)
            local force=0/0; if I and seg and B then force=I*seg*B*s end
            local torque=0/0; if N and I and A and B then torque=N*I*A*B*s end
            local energy=0/0; if L and I then energy=0.5*L*I*I end
            return blong,bsol,force,torque,energy
        end
    })
end

function registerECE216FormulaCoreTopics(calculators)
    ECE216Core.registerParallelPlate(calculators)
    ECE216Core.registerStub(calculators)
    ECE216Core.registerChargeRelax(calculators)
    ECE216Core.registerTransformer(calculators)
    ECE216Core.registerPoynting(calculators)
    ECE216Core.registerMagnetostatics(calculators)
end
