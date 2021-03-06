
#ifndef __ENTRADA_SALIDA_TEXTO__

#define __ENTRADA_SALIDA_TEXTO__

#include "pixelScroll.bas"
#include "Putchars.bas"
#include "bufer.bas"

#define NUM_CARS_POR_LINEA_IMPRESION 64
#define NUM_LINEAS_IMPRESION 24

sub scrollArriba()

	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )
	PixelScrollUp( 1 )

end sub

function esperarTecla() as string
    dim tecla as string
    tecla = ""
    while tecla = ""
            tecla = inkey$
    end while
    while inkey$ <> ""
    end while
    return tecla
end function

function getTiempo AS ULONG
    ' Devuelve FRAMES (1/50 s)
    return INT( 65536 * PEEK( 23674 ) + 256 * PEEK( 23673 ) + PEEK ( 23672 ) )
end function

function esperarTeclaConTimeout( timeout as ulong ) as integer

    ' El parametro es en frames (1/50 s)
    ' Devuelve 1 si se ha pulsado una tecla en el tiempo, o 0 si no

    dim t0 as ulong
    dim t1 as ulong
    t0 = getTiempo()
    t1 = t0

    dim tecla as string
    tecla = ""
    while tecla = ""
            t1 = getTiempo()
            if t1 - t0 > timeout then
                return 0
            end if
            tecla = inkey$
    end while
    return 1
end function

sub imprimirEn( y as integer, x as integer, cad as string )

    'print at y,x; cad( i )
    
    if x < 0 or x >= NUM_CARS_POR_LINEA_IMPRESION or y < 0 or y >= NUM_LINEAS_IMPRESION then
        border 7
    end if
        
    printat64( y, x )
    print64( cad )
    
    
end sub

function imprimirCadenaWrap( cad as string, x0 as integer, y0 as integer, imprimirSoloUltimoCaracter as ubyte, byref xf as integer, byref yf as integer ) as integer

	' x0 e y0 son caracteres desde esquina sup-izq
	' xf e yf tambien. Se devuelve la posicion del ultimo caracter escrito
	' devuelve numero de scrolls hechos (lineas)

	dim x as integer
	dim y as integer
	dim numCars as integer
	dim i as integer
	dim numScrolls as integer
	numScrolls = 0
	
	x = x0
	y = y0
	
	while y >= NUM_LINEAS_IMPRESION
		scrollArriba()
		y = y - 1
		numScrolls = numScrolls + 1
	end while

	numCars = len( cad )
	if numCars > 0 then
		for i = 0 to numCars - 1
			if imprimirSoloUltimoCaracter = 0 or i = numCars - 1 then
				imprimirEn( y, x, cad( i ) )
			end if
			x = x + 1
			if x >= NUM_CARS_POR_LINEA_IMPRESION then
				x = 0
				y = y + 1
				'if y >= NUM_LINEAS_IMPRESION then
				'	i = numCars + 1
				'end if
				while y >= NUM_LINEAS_IMPRESION
					scrollArriba()
					y = y - 1
					numScrolls = numScrolls + 1
				end while
			end if
		next i
	end if

	if i <= numCars then
		imprimirEn( y, x, " " )
	end if

	xf = x
	yf = y
	
	return numScrolls

end function

function imprimirCadenaBuferWrap( indiceInicio as integer, tamCadena as integer, x0 as integer, y0 as integer, byref xf as integer, byref yf as integer ) as integer

	' x0 e y0 son caracteres desde esquina sup-izq
	' xf e yf tambien. Se devuelve la posicion del ultimo caracter escrito (normalmente un espacio)
	' devuelve numero de scrolls hechos (lineas)

	dim x as integer
	dim y as integer
	dim i as integer
	dim c as ubyte
	dim numScrolls as integer
	numScrolls = 0
	
	x = x0
	y = y0
	
	while y >= NUM_LINEAS_IMPRESION
		scrollArriba()
		y = y - 1
		numScrolls = numScrolls + 1
	end while

	if tamCadena > 0 then
		for i = 0 to tamCadena - 1
			c = bufer( i + indiceInicio )
			if c = 13 then
				x = 0
				y = y + 1
			else
				if c <> 10 then
					imprimirEn( y, x, chr( c ) )
					x = x + 1
					if x >= NUM_CARS_POR_LINEA_IMPRESION then
						x = 0
						y = y + 1
					end if
				end if
			end if
			while y >= NUM_LINEAS_IMPRESION
				scrollArriba()
				y = y - 1
				numScrolls = numScrolls + 1
			end while
		next i
	end if

	xf = x
	yf = y
	
	return numScrolls

end function

sub borrarCadenaWrap( cad as string, x0 as integer, y0 as integer )

	' x0 e y0 son caracteres desde esquina sup-izq
	' xf e yf tambien. Se devuelve la posicion del ultimo caracter escrito (normalmente un espacio)
	' devuelve numero de scrolls hechos (lineas)

	dim x as integer
	dim y as integer
	dim numCars as integer
	dim i as integer
	dim numScrolls as integer
	numScrolls = 0
	
	x = x0
	y = y0

	numCars = len( cad )
	if numCars > 0 then
		for i = 0 to numCars - 1
			imprimirEn( y, x, " " )
			x = x + 1
			if x >= NUM_CARS_POR_LINEA_IMPRESION then
				x = 0
				y = y + 1
				'if y >= NUM_LINEAS_IMPRESION then
				'	i = numCars + 1
				'end if
				if y >= NUM_LINEAS_IMPRESION then
					i = numCars
				end if
			end if
		next i
	end if

end sub

function leerCadenaEntrada( cadena as string, byref posYCadena as integer ) as string

	' Enter termina la cadena, backspc o shift + 0 para borrar.

	dim cad1 as string
	dim car as ubyte
	dim carAnt as ubyte
	dim estado as ubyte
	dim imprimir as ubyte
	dim ultCarX as integer
	dim ultCarY as integer
	dim ultCursorX as integer
	dim ultCursorY as integer

	dim posYCopia as integer
	dim numScrolls as integer

	posYCopia = posYCadena
	ultCarX = 0
	ultCarY = posYCopia
	if cadena <> "" then
		numScrolls = imprimirCadenaWrap( cadena, 0, posYCopia, 0, ultCarX, ultCarY )
		posYCopia = posYCopia - numScrolls
	end if

	' Pone cursor flash
	ultCursorX = ultCarX / 2
	ultCursorY = ultCarY
	paint( ultCursorX, ultCursorY, 1, 1, 10111000b)

	' Estado: 0 nada, 1 escribir letra, 2 borrar letra
	estado = 0
	
	bucleLeerCaracter:

	imprimir = 0

	cad1 = inkey$

	if cad1 <> "" then

		car = code( cad1( 0 ) )

		if car = 13 then
			goto finBucleLeerCaracter
		end if
		
		if car = 12 then
			estado = 2
		else
			if estado = 0 then
				carAnt = car
				estado = 1
			end if
		end if
	else
		if estado = 1 then
			if carAnt <> 0 and len(cadena) < TAM_BUFER then
				cadena = cadena + chr( carAnt )
			end if
			estado = 0
			imprimir = 1
		end if 
		if estado = 2 then
			if len( cadena ) > 1 then
				cadena = cadena(TO len( cadena ) - 2 )
			else
				cadena = ""
			end if
			estado = 0
			imprimir = 1
		end if
	end if

	if imprimir <> 0 then

		numScrolls = imprimirCadenaWrap( cadena, 0, posYCopia, 1, ultCarX, ultCarY )
		posYCopia = posYCopia - numScrolls

		' Pone cursor con flash
		paint( ultCursorX, ultCursorY, 1, 1, 00000111b)
		ultCursorX = ultCarX / 2
                ultCursorY = ultCarY
		paint( ultCursorX, ultCursorY, 1, 1, 10000111b)

	end if
	
	goto bucleLeerCaracter

	finBucleLeerCaracter:
	
	while inkey$ <> "" : end while
	
	' Quita cursor flash
	paint( ultCursorX, ultCursorY, 1, 1, 00000111b)

	borrarCadenaWrap( cadena, 0, posYCopia )

	posYCadena = posYCopia

	return cadena

end function
 
function reemplazarCadena( cadena as string, caracterAReemplazar as ubyte, cadenaQueReemplaza as string ) as string

	dim cadenaDevuelta as string
	cadenaDevuelta = ""
	
	dim n as uinteger
	n = len( cadena )
	
	dim c as ubyte
	dim i as uinteger
	for i = 0 to n - 1
		c = code( cadena( i ) )

		if c = caracterAReemplazar then
			cadenaDevuelta = cadenaDevuelta + cadenaQueReemplaza
		else
			cadenaDevuelta = cadenaDevuelta + chr( c )
		end if
	next i
	
	return cadenaDevuelta

end function

function concatenarBuferACadena( cadena as string, indiceInicio as integer, numCarsCopiar as integer ) as string

    dim i as integer
    dim c as ubyte

    for i = 0 to numCarsCopiar - 1

        c = bufer( i + indiceInicio )
        
        cadena = cadena + str( c )

    next i
    
    return cadena

end function

#endif