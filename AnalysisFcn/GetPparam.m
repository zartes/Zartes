function par = GetPparam(p,name)
    %%%Funcion para devolver el array con los valores de un par�metro
    %%%determinado. Pasamos la estructura p a una temperatura fija, no la P()

par = eval(strcat('[','p.',name,'];'));