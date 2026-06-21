#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Generate vendored Lasem GObject enum files for builds without glib-mkenums."""

from __future__ import annotations

import os
import subprocess
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LASEM_SRC = ROOT.parent / "lasem" / "src"
OUT_DIR = ROOT / "generated"

ENUM_SETS = {
    "lsmdomenumtypes": [
        "lsm.h",
        "lsmtypes.h",
        "lsmcairo.h",
        "lsmstr.h",
        "lsmutils.h",
        "lsmmisc.h",
        "lsmdebug.h",
        "lsmtraits.h",
        "lsmproperties.h",
        "lsmattributes.h",
        "lsmitex.h",
        "lsmdomentities.h",
        "lsmdom.h",
        "lsmdomtypes.h",
        "lsmdomnode.h",
        "lsmdomnodelist.h",
        "lsmdomnamednodemap.h",
        "lsmdomdocument.h",
        "lsmdomdocumentfragment.h",
        "lsmdomelement.h",
        "lsmdomcharacterdata.h",
        "lsmdomtext.h",
        "lsmdomview.h",
        "lsmdomparser.h",
        "lsmdomimplementation.h",
    ],
    "lsmmathmlenumtypes": [
        "lsmmathml.h",
        "lsmmathmltypes.h",
        "lsmmathmlenums.h",
        "lsmmathmltraits.h",
        "lsmmathmlattributes.h",
        "lsmmathmldocument.h",
        "lsmmathmlelement.h",
        "lsmmathmlsemanticselement.h",
        "lsmmathmlphantomelement.h",
        "lsmmathmlmathelement.h",
        "lsmmathmltableelement.h",
        "lsmmathmltablerowelement.h",
        "lsmmathmltablecellelement.h",
        "lsmmathmlspaceelement.h",
        "lsmmathmlradicalelement.h",
        "lsmmathmlscriptelement.h",
        "lsmmathmlfractionelement.h",
        "lsmmathmlunderoverelement.h",
        "lsmmathmlpresentationtoken.h",
        "lsmmathmloperatorelement.h",
        "lsmmathmlstringelement.h",
        "lsmmathmlpresentationcontainer.h",
        "lsmmathmlstyleelement.h",
        "lsmmathmlrowelement.h",
        "lsmmathmlencloseelement.h",
        "lsmmathmlfencedelement.h",
        "lsmmathmlpaddedelement.h",
        "lsmmathmlerrorelement.h",
        "lsmmathmlactionelement.h",
        "lsmmathmlstyle.h",
        "lsmmathmlview.h",
        "lsmmathmlglyphtableams.h",
        "lsmmathmlalignmarkelement.h",
        "lsmmathmlaligngroupelement.h",
        "lsmmathmlitexelement.h",
        "lsmmathmlutils.h",
        "lsmmathmllayoututils.h",
    ],
    "lsmsvgenumtypes": [
        "lsmsvg.h",
        "lsmsvgtypes.h",
        "lsmsvgenums.h",
        "lsmsvgtraits.h",
        "lsmsvgattributes.h",
        "lsmsvgstyle.h",
        "lsmsvgcolors.h",
        "lsmsvglength.h",
        "lsmsvgview.h",
        "lsmsvgmatrix.h",
        "lsmsvgdocument.h",
        "lsmsvgelement.h",
        "lsmsvgtransformable.h",
        "lsmsvgclippathelement.h",
        "lsmsvgsvgelement.h",
        "lsmsvgaelement.h",
        "lsmsvggelement.h",
        "lsmsvgdefselement.h",
        "lsmsvguseelement.h",
        "lsmsvgimageelement.h",
        "lsmsvgsymbolelement.h",
        "lsmsvgmarkerelement.h",
        "lsmsvgrectelement.h",
        "lsmsvgcircleelement.h",
        "lsmsvgellipseelement.h",
        "lsmsvglineelement.h",
        "lsmsvgpathelement.h",
        "lsmsvgpolylineelement.h",
        "lsmsvgpolygonelement.h",
        "lsmsvgtextelement.h",
        "lsmsvgtspanelement.h",
        "lsmsvggradientelement.h",
        "lsmsvglineargradientelement.h",
        "lsmsvgradialgradientelement.h",
        "lsmsvgstopelement.h",
        "lsmsvgswitchelement.h",
        "lsmsvgpatternelement.h",
        "lsmsvgmaskelement.h",
        "lsmsvgfilterelement.h",
        "lsmsvgfilterprimitive.h",
        "lsmsvgfilterblend.h",
        "lsmsvgfiltercolormatrix.h",
        "lsmsvgfiltercomposite.h",
        "lsmsvgfilterdisplacementmap.h",
        "lsmsvgfilterconvolvematrix.h",
        "lsmsvgfilterflood.h",
        "lsmsvgfiltergaussianblur.h",
        "lsmsvgfilterimage.h",
        "lsmsvgfilteroffset.h",
        "lsmsvgfiltermerge.h",
        "lsmsvgfiltermergenode.h",
        "lsmsvgfiltermorphology.h",
        "lsmsvgfilterspecularlighting.h",
        "lsmsvgfiltertile.h",
        "lsmsvgfilterturbulence.h",
        "lsmsvgfiltersurface.h",
    ],
}


def find_mkenums() -> str:
    for candidate in (
        os.environ.get("GLIB_MKENUMS"),
        "/usr/bin/glib-mkenums",
        "glib-mkenums",
    ):
        if not candidate:
            continue
        if candidate == "glib-mkenums" or os.path.isfile(candidate):
            return candidate
    raise SystemExit(
        "glib-mkenums not found. Install glib2-devel or set GLIB_MKENUMS."
    )


def run_mkenums(mkenums: str, base: str, headers: list[str], kind: str) -> None:
    inputs = [str(LASEM_SRC / header) for header in headers]
    hdr_name = f"{base}.h"

    if kind == "c":
        fhead = f'#include "{hdr_name}"\n'
        for header in headers:
            fhead += f'#include "{header}"\n'
        fhead += textwrap.dedent(
            """
            #define C_ENUM(v) ((gint) v)
            #define C_FLAGS(v) ((guint) v)
            """
        )
        cmd = [
            mkenums,
            "--fhead",
            fhead,
            "--fprod",
            '/* enumerations from "@basename@" */\n',
            "--vhead",
            textwrap.dedent(
                """
                GType
                @enum_name@_get_type (void)
                {
                    static gsize gtype_id = 0;
                    static const G@Type@Value values[] = {
                """
            ),
            "--vprod",
            '        { C_@TYPE@ (@VALUENAME@), "@VALUENAME@", "@valuename@" },',
            "--vtail",
            textwrap.dedent(
                """
                        { 0, NULL, NULL }
                    };
                    if (g_once_init_enter (&gtype_id)) {
                        GType new_type = g_@type@_register_static (g_intern_static_string ("@EnumName@"), values);
                        g_once_init_leave (&gtype_id, new_type);
                    }
                    return (GType) gtype_id;
                }
                """
            ),
            f"--output={OUT_DIR / f'{base}.c'}",
            *inputs,
        ]
    else:
        cmd = [
            mkenums,
            "--fhead",
            textwrap.dedent(
                f"""
                #pragma once

                #include <glib-object.h>
                G_BEGIN_DECLS
                """
            ),
            "--fprod",
            '/* enumerations from "@basename@" */\n',
            "--vhead",
            textwrap.dedent(
                """
                GType @enum_name@_get_type (void);
                #define @ENUMPREFIX@_TYPE_@ENUMSHORT@ (@enum_name@_get_type())
                """
            ),
            "--ftail",
            "G_END_DECLS",
            f"--output={OUT_DIR / f'{base}.h'}",
            *inputs,
        ]

    subprocess.run(cmd, check=True, cwd=LASEM_SRC)


def main() -> int:
    mkenums = find_mkenums()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for base, headers in ENUM_SETS.items():
        run_mkenums(mkenums, base, headers, "h")
        run_mkenums(mkenums, base, headers, "c")

    print(f"Generated enum files in {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())