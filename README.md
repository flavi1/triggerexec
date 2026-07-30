# triggerexec

`triggerexec` est un démon léger en Python conçu pour intercepter les événements des périphériques d'entrée (`/dev/input/event*`), gérer les combinaisons de touches de manière intelligente (normalisation alphabétique), transformer les sticks et gâchettes analogiques en boutons, et exécuter des commandes shell en fonction de la classe de la fenêtre active sous X11/Wayland (via `kdotool`).

## Prérequis

Le démon nécessite l'installation de la bibliothèque Python `evdev` et les droits d'accès aux périphériques d'entrée :

sudo apt install python3-evdev
sudo usermod -aG input $USER

*(Remarque : Vous devez vous déconnecter/reconnecter pour que le groupe `input` soit pris en compte).*

## Installation (Debian / Ubuntu)

Vous pouvez installer automatiquement la dernière version du paquet `.deb` directement depuis les releases GitHub en une seule commande :

```bash
wget -O triggerexec.deb $(curl -s https://api.github.com/repos/flavi1/triggerexec/releases/latest | grep "browser_download_url" | cut -d '"' -f 4)
sudo apt install ./triggerexec.deb

```

## Configuration

Placez vos fichiers de configuration dans `/etc/triggerexec.d/`. Chaque fichier peut cibler un matériel spécifique grâce à l'en-tête `DEVICE` et combiner des règles globales (en haut du fichier) ainsi que des règles spécifiques par application.

### Exemple 1 : Télécommande infrarouge (`/etc/triggerexec.d/telecommande.conf`)

```ini
DEVICE = CIR transceiver|Consumer Control|rc-core
KEY_VOLUMEUP = amixer sset Master 5%+
KEY_VOLUMEDOWN = amixer sset Master 5%-

```


### Exemple 2 : Manette de jeu (`/etc/triggerexec.d/manette.conf`)

```ini
DEVICE = X-Box|Gamepad|Joystick

[org.libretro.RetroArch]
BTN_SOUTH = ydotool key 28:1 28:0
BTN_PAUSE = kdotool windowclose $(kdotool getactivewindow)

```


## Utilisation

Le script principal s'exécute en arrière-plan et lit les configurations situées dans `/etc/triggerexec.d/`.

## Licence

Distribué sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.
