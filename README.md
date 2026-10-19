# TokTik — Flutter + Firebase

App tipo TikTok con autenticación, feed vertical, likes, cámara, galería, filtros y publicación en Firebase.

## Equipo

| Integrante | Responsabilidad | Estado |
|---|---|---|
| Ari | Firebase, auth, likes | Listo |
| Cruz | Cámara (foto/video) | Listo |
| Juleysi / Iván | Filtros de imagen (+ filtros en feed) | Listo |
| Diego Castro | Subir imagen/video desde galería a Storage | Listo |
| Diego Baños | Integración, pruebas y demo | Listo |

## Cómo correr

```bash
flutter pub get
flutter run
```

Requisitos: Flutter 3.x, proyecto Firebase `tiktokflutter-cca7a` ya configurado (`google-services.json` / `firebase_options.dart`).

### Firebase Storage

En la consola de Firebase → Storage → Rules (para demo/desarrollo):

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /uploads/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Firestore (colección `videos`) debe permitir lectura pública y escritura autenticada según las reglas del proyecto.

## Flujo de la app

1. **Login / Registro** (email + password)
2. **Feed** — scroll vertical, likes, filtros de video en reproducción
3. **Crear**
   - Cámara → vista previa → publicar
   - Galería → elegir imagen/video → publicar (Storage + Firestore)
   - Filtros de imagen (Clarendon, Juno, Lark, Vintage, Snap, etc.)
4. **Perfil** — cerrar sesión

## Checklist de pruebas (Diego Baños)

- [ ] Registrar cuenta nueva e iniciar sesión
- [ ] Ver feed (vacío o con posts existentes)
- [ ] Dar like / quitar like a un post
- [ ] Crear → Cámara → foto → Usar y publicar → aparece en feed
- [ ] Crear → Cámara → video → publicar → aparece en feed
- [ ] Crear → Galería → imagen → publicar
- [ ] Crear → Galería → video → publicar
- [ ] Crear → Filtros de imagen → elegir foto y probar presets
- [ ] En el feed, cambiar filtro Halloween / Navidad
- [ ] Cerrar sesión y volver a entrar

## Guion del video de demostración (~2–3 min)

1. **Intro (10 s)** — “TokTik, plataforma tipo TikTok hecha en Flutter + Firebase.”
2. **Auth (20 s)** — Registro o login con email.
3. **Feed (30 s)** — Scroll vertical, like, filtro de video.
4. **Cámara (30 s)** — Crear → Cámara → grabar o foto → publicar.
5. **Galería (30 s)** — Crear → Galería → elegir media → publicar y mostrar en feed.
6. **Filtros (20 s)** — Crear → Filtros de imagen (Clarendon / Juno / etc.).
7. **Cierre (15 s)** — Perfil → cerrar sesión. Menciones del equipo.

## Estructura relevante

```
lib/
  infrastructure/services/media_upload_service.dart   # Diego Castro
  presentation/screens/
    gallery/gallery_upload_screen.dart                # Diego Castro
    create/create_screen.dart, publish_screen.dart    # Diego Baños
    home/home_shell.dart                              # Diego Baños
    camera/                                           # Cruz
    images/image_filter_screen.dart                   # Juleysi / Iván
    auth/, discover/, profile/
```
