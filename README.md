Ecouter et consulter la web radio bide et musique

avec une interface pensée pour le mobile, vous pouvez :

* Ecouter la radio
* consulter les paroles des chansons
* consulter les commentaires des bidonautes
* voir la page des bidonautes
* voir les pochettes en 3D
* Voir les prochaines chansons dans la playlist
* Rechercher des chansons
* Voir le mur des messages
* Voir le Trombidoscope
* Voir le pochettoscope
* Voir les nouvelles entrées dans la base
* Organiser les favoris

# Installation 

## Android 

<a href="https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique"><img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" height=60px /></a>

[![Available on F-Droid](https://f-droid.org/wiki/images/c/c4/F-Droid-button_available-on.png)](https://f-droid.org/repository/browse/?fdid=fr.odrevet.bide_et_musique)

ou télécharger l'apk depuis [les releases github](https://github.com/odrevet/bide_et_musique_flutter/releases/latest) 

## IOS (iphone and ipad)

https://apps.apple.com/fr/app/bide-et-musique/id1524513644

# Vidéo de présentation 

[![Watch the video](https://img.youtube.com/vi/Zsl5Qezuqh0/0.jpg)](https://www.youtube.com/watch?v=Zsl5Qezuqh0)

# Captures d'écran 

|  <img src="/fastlane/metadata/android/en-US/images/phoneScreenshots/main.jpg" width="240px" /> |  <img src="/fastlane/metadata/android/en-US/images/phoneScreenshots/menu.jpg" width="240px" /> |
|---|---|
| <img src="/fastlane/metadata/android/en-US/images/phoneScreenshots/titres.jpg" width="240px" />  | <img src="/fastlane/metadata/android/en-US/images/phoneScreenshots/page_chanson.jpg" width="240px" />  |


# Release

## android

* Editer le ficher `android/app/build.gradle` et dé-commenter

```
    /*signingConfigs {
        release {
            ...
        }
    }*/
```

ainsi que

```
//signingConfig signingConfigs.release
```

* Editer le fichier `android/key.properties` et ajouter les clés (secretes, ne pas les commit) ainsi que le chemin vers la clé privée .jks générée au préalable.

* Créer un apk 

```
    flutter build apk
```

* Créer un appbundle 

```
    flutter build appbundle
```
