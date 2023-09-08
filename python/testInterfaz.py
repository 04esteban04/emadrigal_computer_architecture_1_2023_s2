import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk
import subprocess
import cv2
import os
import time


def crearImagen(values):
    # Crea una matriz de 640x480 a partir de 'values'
    width, height = 640, 480
    matrix = [values[i:i+width] for i in range(0, len(values), width)]

    # Convierte la matriz en una imagen
    image = Image.new("L", (width, height))  # "L" significa escala de grises
    image.putdata([pixel for row in matrix for pixel in row])

    # Guarda la imagen en un archivo con el nombre generado
    image.save("../assets/imagenFiltro.png")

def Asm():
    os.chdir("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assembly")

    # Definir los comandos como una lista de cadenas
    comandos = [
        "arm-none-eabi-as main.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o main.o",
        "arm-none-eabi-as itoa.s -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3 -g -o itoa.o",
        "arm-none-eabi-ld main.o itoa.o -o main"
    ]
    

    # Ejecutar cada comando en la lista
    for comando in comandos:
        subprocess.run(comando, shell=True)
    
    # Ejecuta el comando "./main" y captura la salida estándar
    output = subprocess.check_output(["./main"], universal_newlines=True)

    # Divide la salida en líneas y convierte cada línea en un entero
    values = [int(line.strip()) for line in output.splitlines()]
    return values

def meterTxt(ruta):
    # Ruta de la imagen
    imagen_path = ruta
    archivo_txt_path = '/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assembly/INPUT.txt'

    # Verificar si la imagen existe
    if not os.path.exists(imagen_path):
        print(f"La imagen '{imagen_path}' no existe.")
    else:
        # Cargar la imagen
        imagen = cv2.imread(imagen_path)

        if imagen is not None:
            # Cambiar la dimensión a 640x480
            nueva_dimension = (640, 480)
            imagen_redimensionada = cv2.resize(imagen, nueva_dimension)

            # Convertir la imagen a escala de grises
            imagen_gris = cv2.cvtColor(imagen_redimensionada, cv2.COLOR_BGR2GRAY)

            # Obtener las dimensiones de la imagen
            alto, ancho = imagen_gris.shape

            # Crear un archivo de texto para almacenar los valores de píxeles
            with open(archivo_txt_path, 'w') as archivo_txt:
                # Iterar a través de la imagen y escribir los valores de píxeles uno por uno en el archivo de texto
                for fila in range(alto):
                    for columna in range(ancho):
                        valor_pixel = imagen_gris[fila, columna]
                        archivo_txt.write(str(valor_pixel) + '\n')

            #print("Valores de píxeles guardados uno por uno en 'INPUT.txt'")
        else:
            print(f"No se pudo cargar la imagen '{imagen_path}'.")

# Función para cargar y redimensionar las imágenes
def cargar_imagenes(imagenFiltro):
    # Cargar las imágenes originales y las imágenes obtenidas
    imagen_obtenida = Image.open(imagenFiltro)
    # Redimensionar las imágenes
    imagen_obtenida = imagen_obtenida.resize((640, 480))
    # Convertir las imágenes en formato adecuado para tkinter
    imagen_obtenida_tk = ImageTk.PhotoImage(imagen_obtenida)
    imagen_obtenida = ttk.Label(ventana, text="Imagen obtenida")
    # Colocar las etiquetas en la cuadrícula
    imagen_obtenida.grid(row=1, column=1, padx=70, pady=10)
    # Actualizar las etiquetas y las imágenes en la interfaz gráfica
    imagen_obtenida.config(image=imagen_obtenida_tk)
    # Guardar referencias a las imágenes para evitar que sean eliminadas
    imagen_obtenida.image = imagen_obtenida_tk

def cargarImagenOriginal(imagenOriginal):
    imagen_original = Image.open(imagenOriginal)
    imagen_original = imagen_original.resize((640, 480))
    imagen_original_tk = ImageTk.PhotoImage(imagen_original)
    imagen_original = ttk.Label(ventana, text="Imagen original")
    imagen_original.grid(row=1, column=0, padx=50, pady=10)
    imagen_original.config(image=imagen_original_tk)
    imagen_original.image = imagen_original_tk

# Función para posicionar la ventana en el centro de la pantalla
def posVentana(ventana):
    # Obtener las dimensiones de la pantalla
    ancho_pantalla = ventana.winfo_screenwidth()
    alto_pantalla = ventana.winfo_screenheight()

    # Obtener el ancho y alto de la ventana
    ancho_ventana = 1500  
    alto_ventana = 570   

    # Calcular la posición para centrar la ventana
    x_pos = (ancho_pantalla - ancho_ventana) // 2
    y_pos = (alto_pantalla - alto_ventana) // 2

    # Configurar la geometría de la ventana para centrarla
    ventana.geometry(f"{ancho_ventana}x{alto_ventana}+{x_pos}+{y_pos}")

# Función que se ejecutará cuando se haga clic en el botón
def accion_del_boton():
    meterTxt("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/sekiroGris.jpg")
    values = Asm()
    crearImagen(values)
    cargar_imagenes("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/imagenFiltro.png")
    for i in range(40):   
        meterTxt("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/imagenFiltro.png")
        values = Asm()
        crearImagen(values)
        cargar_imagenes("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/imagenFiltro.png")
        ventana.update()
        ventana.update_idletasks()
        print(i)

# Crear la ventana principal
ventana = tk.Tk()
ventana.title("Visualizador de Imágenes")
ventana.maxsize(1500, 570)

posVentana(ventana)

# Crear etiquetas para las imágenes originales y obtenidas
labelImagenOriginal = ttk.Label(ventana, text="Imagen original")
labelImagenObtenida = ttk.Label(ventana, text="Imagen con Rippling")

# Colocar las etiquetas en la cuadrícula 1x2
labelImagenOriginal.grid(row=0, column=0, padx=50, pady=10)
labelImagenObtenida.grid(row=0, column=1, padx=70, pady=10)

cargarImagenOriginal("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/sekiro.jpg")

# Cargar las imágenes automáticamente al iniciar la aplicación
cargar_imagenes("/home/daval/Escritorio/Arqui/Proyecto_1/emadrigal_computer_architecture_1_2023_s2/assets/sekiroGris.jpg")


# Crear un botón en el medio de la ventana
boton = ttk.Button(ventana, text="Run", command=accion_del_boton)
boton.grid(row=0, column=0, columnspan=2, pady=20)  # Se coloca en la segunda fila y abarca ambas columnas

# Iniciar la interfaz gráfica
ventana.mainloop()