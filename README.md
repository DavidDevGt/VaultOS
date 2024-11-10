# VaultOS

## Descripción

**VaultOS** es un sistema avanzado de gestión de almacenamiento para **ComputerCraft** en Minecraft. Permite organizar, monitorear y administrar de manera eficiente todos tus cofres y recursos dentro del juego, facilitando el acceso y la administración de tus materiales y herramientas.

## Características

- **Dashboard Interactivo:** Una interfaz gráfica para visualizar y gestionar tus cofres y recursos.
- **Organización de Cofres:** Clasifica y categoriza automáticamente los ítems almacenados en tus cofres.
- **Gestión de Almacenamiento:** Herramientas para agregar, eliminar y modificar el contenido de tus cofres.
- **Funciones Utilitarias:** Scripts auxiliares para mejorar la funcionalidad y eficiencia del sistema.
- **Interfaz de Usuario (TUI):** Navegación fácil y amigable a través de menús y opciones.

## Estructura de Archivos

```
VaultOS/
├── code.lua
├── dashboard.lua
├── fts.lua
├── grid.lua
├── main.lua
├── startup
│   └── 31_startup.lua
├── startup.lua
├── storage.lua
├── sys_utils
│   ├── disk.lua
│   └── infraestructure.lua
├── tui.lua
└── utils.lua
```

- **main.lua:** Archivo principal que inicia el sistema VaultOS.
- **dashboard.lua:** Gestiona el panel de control interactivo.
- **tui.lua:** Maneja la interfaz de usuario basada en texto.
- **storage.lua:** Funciones relacionadas con la gestión de almacenamiento.
- **utils.lua:** Funciones utilitarias generales.
- **fts.lua y grid.lua:** Scripts adicionales para funcionalidades específicas.
- **sys_utils/**: Carpeta que contiene utilidades del sistema.
  - **disk.lua:** Manejo de almacenamiento en disco.
  - **infraestructure.lua:** Funciones relacionadas con la infraestructura del sistema.
- **startup.lua y startup/31_startup.lua:** Scripts que se ejecutan al salir de VaultOS.

## Instalación

Sigue estos pasos para instalar **VaultOS** en tu computadora dentro de Minecraft:

1. **Clonar el Repositorio:**

   Abre tu terminal y clona el repositorio de VaultOS utilizando el siguiente comando:

   ```lua
   git clone https://github.com/DavidDevGt/VaultOS.git
   ```

   *Nota: puedes descargar los archivos directamente desde GitHub y transferirlos a tu computadora en el juego.*

2. **Navegar al Directorio de VaultOS:**

   ```lua
   cd VaultOS
   ```

3. **Configurar los Scripts de Inicio:**

   Asegúrate de que los scripts de inicio estén correctamente configurados para ejecutarse al iniciar la computadora. Puedes editar `startup.lua` si es necesario.

4. **Ejecutar el Sistema:**

   Inicia **VaultOS** ejecutando el script principal:

   ```lua
   lua main.lua
   ```

## Uso

Una vez instalado, **VaultOS** ofrece varias funcionalidades a través de su interfaz de usuario. A continuación, se detallan las principales acciones que puedes realizar:

1. **Acceder al Dashboard:**

   Al iniciar **VaultOS**, se abrirá automáticamente el panel de control interactivo donde podrás ver el estado de tus cofres y recursos.

2. **Gestionar Cofres:**

   - **Agregar un Cofre:** Permite registrar nuevos cofres en el sistema para su gestión.
   - **Eliminar un Cofre:** Retira cofres existentes de la gestión de **VaultOS**.
   - **Modificar Contenido:** Agrega, elimina o actualiza ítems dentro de los cofres registrados.

3. **Navegar por las Categorías:**

   Utiliza la interfaz de usuario para navegar entre diferentes categorías de ítems, facilitando la búsqueda y organización.

4. **Utilizar Funciones Avanzadas:**

   **VaultOS** incluye scripts adicionales que puedes ejecutar para tareas específicas, como búsquedas avanzadas o integraciones con otros sistemas.

## Contribución

¡Las contribuciones son bienvenidas! Si deseas mejorar **VaultOS**, sigue estos pasos:

1. **Fork el Repositorio:**

   Crea una copia del repositorio en tu cuenta de GitHub.

2. **Crea una Rama de Funcionalidad:**

   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```

3. **Realiza los Cambios:**

   Implementa tus mejoras o correcciones.

4. **Commit y Push:**

   ```bash
   git commit -m "Añadir nueva funcionalidad X"
   git push origin feature/nueva-funcionalidad
   ```

5. **Abre un Pull Request:**

   Desde tu fork, abre un pull request describiendo los cambios realizados.
