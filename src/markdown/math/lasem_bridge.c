/* SPDX-License-Identifier: AGPL-3.0-or-later */

#include "lasem_bridge.h"

#include <string.h>

#include <lsmdomdocument.h>
#include <lsmdomview.h>
#include <lsmmathmldocument.h>
#include <lsmmathmlmathelement.h>
#include <lsmmathmlstyle.h>

static gboolean
parse_hex_color (const char *color, double *red, double *green, double *blue)
{
    unsigned int r = 0;
    unsigned int g = 0;
    unsigned int b = 0;
    const char *hex;

    g_return_val_if_fail (color != NULL, FALSE);
    g_return_val_if_fail (red != NULL, FALSE);
    g_return_val_if_fail (green != NULL, FALSE);
    g_return_val_if_fail (blue != NULL, FALSE);

    hex = color;
    if (*hex == '#') {
        hex++;
    }

    if (strlen (hex) == 3) {
        if (sscanf (hex, "%1x%1x%1x", &r, &g, &b) != 3) {
            return FALSE;
        }
        r = (r << 4) | r;
        g = (g << 4) | g;
        b = (b << 4) | b;
    } else if (strlen (hex) == 6) {
        if (sscanf (hex, "%2x%2x%2x", &r, &g, &b) != 3) {
            return FALSE;
        }
    } else {
        return FALSE;
    }

    *red = r / 255.0;
    *green = g / 255.0;
    *blue = b / 255.0;
    return TRUE;
}

struct _MarkViewerMathView {
    int refcount;
    LsmDomDocument *document;
    LsmDomView *view;
};

MarkViewerMathView *
markviewer_math_view_ref (MarkViewerMathView *view)
{
    if (view != NULL) {
        view->refcount++;
    }

    return view;
}

MarkViewerMathView *
markviewer_math_view_from_latex (const char *latex, GError **error)
{
    LsmMathmlDocument *document;
    LsmDomView *view;
    MarkViewerMathView *math_view;

    g_return_val_if_fail (latex != NULL, NULL);

    document = lsm_mathml_document_new_from_itex (latex, -1, error);
    if (document == NULL) {
        return NULL;
    }

    view = lsm_dom_document_create_view (LSM_DOM_DOCUMENT (document));
    if (view == NULL) {
        g_object_unref (document);
        g_set_error (error, G_FILE_ERROR, G_FILE_ERROR_FAILED, "Failed to create Lasem view");
        return NULL;
    }

    math_view = g_new0 (MarkViewerMathView, 1);
    math_view->refcount = 1;
    math_view->document = LSM_DOM_DOCUMENT (document);
    math_view->view = view;
    return math_view;
}

void
markviewer_math_view_unref (MarkViewerMathView *view)
{
    if (view == NULL) {
        return;
    }

    view->refcount--;
    if (view->refcount > 0) {
        return;
    }

    g_clear_object (&view->view);
    g_clear_object (&view->document);
    g_free (view);
}

void
markviewer_math_view_set_resolution (MarkViewerMathView *view, double ppi)
{
    g_return_if_fail (view != NULL && view->view != NULL);
    lsm_dom_view_set_resolution (view->view, ppi);
}

void
markviewer_math_view_set_foreground (MarkViewerMathView *view, const char *color)
{
    LsmMathmlDocument *document;
    LsmMathmlMathElement *math_element;
    LsmMathmlStyle *style;
    double red;
    double green;
    double blue;

    g_return_if_fail (view != NULL && view->document != NULL);

    if (color == NULL || color[0] == '\0') {
        return;
    }

    if (!parse_hex_color (color, &red, &green, &blue)) {
        return;
    }

    document = LSM_MATHML_DOCUMENT (view->document);
    math_element = lsm_mathml_document_get_root_element (document);
    if (math_element == NULL) {
        return;
    }

    style = lsm_mathml_math_element_get_default_style (math_element);
    if (style == NULL) {
        return;
    }

    lsm_mathml_style_set_math_color (style, red, green, blue, 1.0);
    lsm_mathml_math_element_update (math_element);
}

void
markviewer_math_view_set_math_size (MarkViewerMathView *view, double size_pt)
{
    LsmMathmlDocument *document;
    LsmMathmlMathElement *math_element;
    LsmMathmlStyle *style;

    g_return_if_fail (view != NULL && view->document != NULL);
    g_return_if_fail (size_pt > 0.0);

    document = LSM_MATHML_DOCUMENT (view->document);
    math_element = lsm_mathml_document_get_root_element (document);
    if (math_element == NULL) {
        return;
    }

    style = lsm_mathml_math_element_get_default_style (math_element);
    if (style == NULL) {
        return;
    }

    lsm_mathml_style_set_math_size_pt (style, size_pt);
    lsm_mathml_math_element_update (math_element);
}

void
markviewer_math_view_get_size_pixels (
    MarkViewerMathView *view,
    unsigned int *width,
    unsigned int *height,
    unsigned int *baseline
)
{
    g_return_if_fail (view != NULL && view->view != NULL);
    lsm_dom_view_get_size_pixels (view->view, width, height, baseline);
}

void
markviewer_math_view_render (MarkViewerMathView *view, cairo_t *cr, double x, double y)
{
    g_return_if_fail (view != NULL && view->view != NULL);
    lsm_dom_view_render (view->view, cr, x, y);
}