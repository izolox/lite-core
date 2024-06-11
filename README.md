# Lite-Core

**Lite-Core** is a lightweight core used for script prototyping within the FiveM. Designed to be minimalistic yet powerful, Lite-Core helps you get your scripts up and running quickly without unnecessary overhead. This core script leverages `ox_lib` as its only dependency to keep things simple and efficient.

## Features

- Minimalistic and lightweight design
- Quick setup for prototyping scripts
- Utilizes `ox_lib` for essential functionalities
- Easy integration into existing FiveM projects

## Requirements

- FiveM server
- `ox_lib`

## Installation

1. **Download the repository:**

    Clone the repository to your local machine:
    ```bash
    git clone https://github.com/yourusername/lite-core.git
    ```

2. **Add to your FiveM server:**

    Copy the `lite-core` folder to your FiveM server's `resources` directory.

3. **Install `ox_lib`:**

    Make sure you have `ox_lib` installed on your server. You can find `ox_lib` [here](https://github.com/overextended/ox_lib).

4. **Update your `server.cfg`:**

    Add the following lines to your `server.cfg` to ensure that `ox_lib` and `lite-core` are started:

    ```cfg
    ensure ox_lib
    ensure lite-core
    ```

## Usage

After installing and starting Lite-Core, you can begin using it to prototype your scripts. The core provides essential functionalities needed for script development, allowing you to focus on building and testing your ideas. Instead of using a traditional database to store data, Lite-Core utilizes FiveM's native KVPs (Key-Value Pairs) to store character and vehicle data, simplifying data management and improving performance.

## Contributing

We welcome contributions to Lite-Core! If you have ideas for improvements or have found a bug, feel free to open an issue or submit a pull request.

1. Fork the repository.
2. Create a new branch with a descriptive name.
3. Make your changes and commit them.
4. Push your changes to your fork.
5. Open a pull request with a detailed description of your changes.

## License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.

## Acknowledgments

- Thanks to the `ox_lib` team for their excellent library that Lite-Core is built upon.

## Contact

For any questions or support, feel free to open an issue or contact me directly on discord `izolox#0`.

---

**Note:** Detailed documentation for Lite-Core is currently in progress and will be made available soon. Stay tuned!

---

Enjoy prototyping with Lite-Core!
