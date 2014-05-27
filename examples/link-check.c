/*
* Smoke-check for building
*/

#include <uuid.h>
#include <glib.h>
#include <gegl.h>
#include <gegl-plugin.h>
#include <png.h>
#include <json-glib/json-glib.h>
#include <libsoup/soup.h>

void
check_png(void) {
    png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
}

void
check_json_glib(void) {
    JsonParser *parser = json_parser_new();
    g_object_unref(parser);
}

void
check_libsoup(void) {
    SoupServer *server = soup_server_new(SOUP_SERVER_PORT, 6666,
                SOUP_SERVER_SERVER_HEADER, "link-check", NULL);
    g_object_unref(server);
}

void
check_gegl(void) {
    GeglNode *node = gegl_node_new();
    g_object_unref(node);
}

void
check_uuid(void) {
    uuid_t u;
    uuid_generate(u);
}

int
main(int argc, char *argv[]) {

    gegl_init(0, NULL);

    check_png();
    check_json_glib();
    check_libsoup();
    check_gegl();

    gegl_exit();
    return 0;
}
