function I=Fit_I_Step(p,t)
%%%Funci�n para ajustar la respuesta de un sistema ante funci�n escal�n
%%%asumiendo modelo a 1 bloque.

I=heaviside(t-p(5)).*(p(1)*(1-(1+p(2))*exp(t/p(3))+p(2)*exp(t/p(4))));