#ifndef H_RASTERIZER_MODE13
#define H_RASTERIZER_MODE13

#include "common.h"

//extern uint8 gLightmap[256 * 32];
extern uint8* gLightmap;
extern const uint8* gTile;

#ifdef USE_ASM
    extern "C" {
        void rasterize_dummy(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeS_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeF_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        //void rasterizeG_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeFT_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeGT_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeFTA_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeGTA_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeLineH_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeLineV_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
        void rasterizeFillS_asm(uint16* pixel, const VertexLink* L, const VertexLink* R);
    }

    #define rasterizeS rasterizeS_asm
    #define rasterizeF rasterizeF_asm
    //#define rasterizeG rasterizeG_asm
    #define rasterizeFT rasterizeFT_asm
    #define rasterizeGT rasterizeGT_asm
    #define rasterizeFTA rasterizeFTA_asm
    #define rasterizeGTA rasterizeGTA_asm
    #define rasterizeSprite rasterizeSprite_c
    #define rasterizeLineH rasterizeLineH_asm
    #define rasterizeLineV rasterizeLineV_asm
    #define rasterizeFillS rasterizeFillS_asm
#else
    #define rasterizeS rasterizeS_c
    #define rasterizeF rasterizeF_c
    //#define rasterizeG rasterizeG_c
    #define rasterizeFT rasterizeFT_c
    #define rasterizeGT rasterizeGT_c
    #define rasterizeFTA rasterizeFTA_c
    #define rasterizeGTA rasterizeGTA_c
    #define rasterizeSprite rasterizeSprite_c
    #define rasterizeLineH rasterizeLineH_c
    #define rasterizeLineV rasterizeLineV_c
    #define rasterizeFillS rasterizeFillS_c

void rasterizeS_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    const uint8* ft_lightmap = &gLightmap[0x1A00];

    int32 Lh = 0;
    int32 Rh = 0;
    int32 Ldx = 0;
    int32 Rdx = 0;
    int32 Rx;
    int32 Lx;

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;

            if (Lh > 1)
            {
                uint32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);
            }

            Lx <<= 16;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;

            if (Rh > 1) {
                uint32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);
            }

            Rx <<= 16;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                uint8* ptr = (uint8*)pixel + x1;

                if (x1 & 1)
                {
                    ptr[0] = ft_lightmap[ptr[0]];
                    ptr++;
                    width--;
                }

                if (width & 1)
                {
                    width--;
                    ptr[width] = ft_lightmap[ptr[width]];
                }

                while (width)
                {
                    ptr[0] = ft_lightmap[ptr[0]];
                    ptr[1] = ft_lightmap[ptr[1]];
                    ptr += 2;
                    width -= 2;
                }
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
        }
    }
}

void rasterizeF_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    uint32 color = gLightmap[(L->v.g << 8) | (uint32)R];
    color |= (color << 8);

    int32 Lh = 0;
    int32 Rh = 0;
    int32 Ldx = 0;
    int32 Rdx = 0;
    int32 Rx;
    int32 Lx;

    R = L;

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            ASSERT(L->v.y >= 0);

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;

            if (Lh > 1)
            {
                uint32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);
            }

            Lx <<= 16;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            ASSERT(R->v.y >= 0);

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;

            if (Rh > 1) {
                uint32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);
            }

            Rx <<= 16;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                uint8* ptr = (uint8*)pixel + x1;

                if (intptr_t(ptr) & 1)
                {
                    *ptr++ = uint8(color);
                    width--;
                }

                if (width & 1)
                {
                    ptr[width - 1] = uint8(color);
                }

                if (width & 2)
                {
                    *(uint16*)ptr = color;
                    ptr += 2;
                }

                width >>= 2;
                while (width--)
                {
#if 1
                    *(uint32*)ptr = color | color << 16;
                    ptr += 4;
#else
                    *(uint16*)ptr = color;
                    ptr += 2;
                    *(uint16*)ptr = color;
                    ptr += 2;
#endif
                }
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
        }
    }
}

void rasterizeFT_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    const uint8* ft_lightmap = &gLightmap[L->v.g << 8];
    const uint8* tile = gTile;

    int32 Lh = 0, Rh = 0;
    int32 Lx, Rx, Ldx = 0, Rdx = 0;
    uint32 Lt, Rt, Ldt, Rdt;
    Ldt = 0;
    Rdt = 0;

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;
            Lt = L->t.t;

            if (Lh > 1)
            {
                int32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);

                uint32 duv = N->t.t - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Ldt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Lx <<= 16;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;
            Rt = R->t.t;

            if (Rh > 1)
            {
                int32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);

                uint32 duv = N->t.t - Rt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Rdt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Rx <<= 16;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                uint32 tmp = FixedInvU(width);

                uint32 duv = Rt - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                uint32 dtdx = (du & 0xFFFF0000) | (dv >> 16);

                uint32 t = Lt;

                uint8* ptr = (uint8*)pixel + x1;

                if (intptr_t(ptr) & 1)
                {
                    *ptr++ = ft_lightmap[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;
                    width--;
                }

                if (width & 1)
                {
                    uint32 tmp = Rt - dtdx;
                    ptr[width - 1] = ft_lightmap[tile[(tmp & 0xFF00) | (tmp >> 24)]];
                }

                width >>= 1;
            #ifdef TEX_2PX
                dtdx <<= 1;

                while (width--)
                {
                    uint8 indexA = ft_lightmap[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;

                    *(uint16*)ptr = indexA | (indexA << 8);

                    ptr += 2;
                }
            #else
                while (width--)
                {
                    uint8 indexA = ft_lightmap[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;
                    uint8 indexB = ft_lightmap[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;
                    
                    *(uint16*)ptr = indexB | (indexA << 8);

                    ptr += 2;
                }
            #endif
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
            Lt += Ldt;
            Rt += Rdt;
        }
    }
}

void rasterizeGT_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
#ifdef ALIGNED_LIGHTMAP
    ASSERT((intptr_t(gLightmap) & 0xFFFF) == 0); // lightmap should be 64k aligned
#endif

    const uint8* lightmap = gLightmap;
    const uint8* tile = gTile;

    int32 Lh = 0, Rh = 0;
    int32 Lx, Rx, Lg, Rg, Ldx = 0, Rdx = 0, Ldg = 0, Rdg = 0;
    uint32 Lt, Rt, Ldt, Rdt;
    Ldt = 0;
    Rdt = 0;

    // 8-bit fractional part precision for Gouraud component
    // has some artifacts but allow to save one reg for inner loop
    // with aligned by 64k address of lightmap array

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;
            Lg = L->v.g;
            Lt = L->t.t;

            if (Lh > 1)
            {
                int32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);
                Ldg = tmp * (N->v.g - Lg) >> 8;

                uint32 duv = N->t.t - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Ldt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Lx <<= 16;
            Lg <<= 8;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;
            Rg = R->v.g;
            Rt = R->t.t;

            if (Rh > 1)
            {
                int32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);
                Rdg = tmp * (N->v.g - Rg) >> 8;

                uint32 duv = N->t.t - Rt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Rdt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Rx <<= 16;
            Rg <<= 8;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

    #ifdef ALIGNED_LIGHTMAP
        Lg |= intptr_t(gLightmap);
        Rg |= intptr_t(gLightmap);
    #endif

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                int32 tmp = FixedInvU(width);

                int32 dgdx = tmp * (Rg - Lg) >> 15;

                uint32 duv = Rt - Lt;
                uint32 u = tmp * int16(duv >> 16);
                uint32 v = tmp * int16(duv);
                uint32 dtdx = (u & 0xFFFF0000) | (v >> 16);

                int32 g = Lg;
                uint32 t = Lt;

                uint8* ptr = (uint8*)pixel + x1;

                if (intptr_t(ptr) & 1)
                {
                #ifdef ALIGNED_LIGHTMAP
                    const uint8* LMAP = (uint8*)(g >> 8 << 8);
                    uint8 indexA = LMAP[tile[(t & 0xFF00) | (t >> 24)]];
                #else
                    uint8 indexA = lightmap[(g >> 8 << 8) | tile[(t & 0xFF00) | (t >> 24)]];
                #endif
                    *ptr++ = indexA;
                    t += dtdx;
                    g += dgdx >> 1;
                    width--;
                }

                if (width & 1)
                {
                    uint32 tmp = Rt - dtdx;
                #ifdef ALIGNED_LIGHTMAP
                    const uint8* LMAP = (uint8*)(Rg >> 8 << 8);
                    uint8 indexA = LMAP[tile[(tmp & 0xFF00) | (tmp >> 24)]];
                #else
                    uint8 indexA = lightmap[(Rg >> 8 << 8) | tile[(tmp & 0xFF00) | (tmp >> 24)]];
                #endif
                    ptr[width - 1] = indexA;
                }

                width >>= 1;

            #ifdef TEX_2PX
                dtdx <<= 1;
                while (width--)
                {
                #ifdef ALIGNED_LIGHTMAP
                    const uint8* LMAP = (uint8*)(g >> 8 << 8);
                    uint8 indexA = LMAP[tile[(t & 0xFF00) | (t >> 24)]];
                #else
                    uint8 indexA = lightmap[(g >> 8 << 8) | tile[(t & 0xFF00) | (t >> 24)]];
                #endif
                    *(uint16*)ptr = indexA | (indexA << 8);
                    ptr += 2;
                    t += dtdx;
                    g += dgdx;
                }
            #else
                while (width--)
                {
                #ifdef ALIGNED_LIGHTMAP
                    const uint8* LMAP = (uint8*)(g >> 8 << 8);
                #else
                    const uint8* LMAP = &lightmap[g >> 8 << 8];
                #endif

                    uint8 indexA = LMAP[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;
                    uint8 indexB = LMAP[tile[(t & 0xFF00) | (t >> 24)]];
                    t += dtdx;
                    g += dgdx;
                    
                    *(uint16*)ptr = indexB | (indexA << 8);

                    ptr += 2;
                }
            #endif
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
            Lg += Ldg;
            Rg += Rdg;
            Lt += Ldt;
            Rt += Rdt;
        }
    }
}

void rasterizeFTA_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    const uint8* ft_lightmap = &gLightmap[L->v.g << 8];
    const uint8* tile = gTile;

    int32 Lh = 0, Rh = 0;
    int32 Lx, Rx, Ldx = 0, Rdx = 0;
    uint32 Lt, Rt, Ldt, Rdt;
    Ldt = 0;
    Rdt = 0;

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;
            Lt = L->t.t;

            if (Lh > 1)
            {
                int32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);

                uint32 duv = N->t.t - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Ldt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Lx <<= 16;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;
            Rt = R->t.t;

            if (Rh > 1)
            {
                int32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);

                uint32 duv = N->t.t - Rt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Rdt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Rx <<= 16;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                uint32 tmp = FixedInvU(width);

                uint32 duv = Rt - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                uint32 dtdx = (du & 0xFFFF0000) | (dv >> 16);

                uint32 t = Lt;

                uint8* ptr = (uint8*)pixel + x1;

                if (intptr_t(ptr) & 1)
                {
                    uint8 indexB = tile[(t & 0xFF00) | (t >> 24)];
                    if (indexB) {
                        *ptr = ft_lightmap[indexB];
                    }
                    ptr++;
                    t += dtdx;
                    width--;
                }

                if (width & 1)
                {
                    uint32 tmp = Rt - dtdx;
                    uint8 indexA = tile[(tmp & 0xFF00) | (tmp >> 24)];
                    if (indexA) {
                        ptr[width - 1] = ft_lightmap[indexA];
                    }
                }

                width >>= 1;
            #ifdef TEX_2PX
                dtdx <<= 1;

                while (width--)
                {
                    uint8 indexA = tile[(t & 0xFF00) | (t >> 24)];
                    t += dtdx;

                    if (indexA) {
                        indexA = ft_lightmap[indexA];
                        *(uint16*)ptr = indexA | (indexA << 8);
                    }

                    ptr += 2;
                }
            #else
                while (width--)
                {
                    uint8 indexA = tile[(t & 0xFF00) | (t >> 24)];
                    t += dtdx;
                    uint8 indexB = tile[(t & 0xFF00) | (t >> 24)];
                    t += dtdx;
                    
                    if (indexA && indexB) {
                        *(uint16*)ptr = ft_lightmap[indexB] | (ft_lightmap[indexA] << 8);
                    } /*else if (indexA) {
                        *(uint16*)ptr = (*(uint16*)ptr & 0xFF00) | ft_lightmap[indexA];
                    } else if (indexB) {
                        *(uint16*)ptr = (*(uint16*)ptr & 0x00FF) | (ft_lightmap[indexB] << 8);
                    }*/

                    ptr += 2;
                }
            #endif
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
            Lt += Ldt;
            Rt += Rdt;
        }
    }
}

void rasterizeGTA_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
#ifdef ALIGNED_LIGHTMAP
    ASSERT((intptr_t(gLightmap) & 0xFFFF) == 0); // lightmap should be 64k aligned
#endif

    const uint8* lightmap = gLightmap;
    const uint8* tile = gTile;

    int32 Lh = 0, Rh = 0;
    int32 Lx, Rx, Lg, Rg, Ldx = 0, Rdx = 0, Ldg = 0, Rdg = 0;
    uint32 Lt, Rt, Ldt, Rdt;
    Ldt = 0;
    Rdt = 0;

    // 8-bit fractional part precision for Gouraud component
    // has some artifacts but allow to save one reg for inner loop
    // with aligned by 64k address of lightmap array

    while (1)
    {
        while (!Lh)
        {
            const VertexLink* N = L + L->prev;

            if (N->v.y < L->v.y) return;

            Lh = N->v.y - L->v.y;
            Lx = L->v.x;
            Lg = L->v.g;
            Lt = L->t.t;

            if (Lh > 1)
            {
                int32 tmp = FixedInvU(Lh);
                Ldx = tmp * (N->v.x - Lx);
                Ldg = tmp * (N->v.g - Lg) >> 8;

                uint32 duv = N->t.t - Lt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Ldt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Lx <<= 16;
            Lg <<= 8;
            L = N;
        }

        while (!Rh) 
        {
            const VertexLink* N = R + R->next;

            if (N->v.y < R->v.y) return;

            Rh = N->v.y - R->v.y;
            Rx = R->v.x;
            Rg = R->v.g;
            Rt = R->t.t;

            if (Rh > 1)
            {
                int32 tmp = FixedInvU(Rh);
                Rdx = tmp * (N->v.x - Rx);
                Rdg = tmp * (N->v.g - Rg) >> 8;

                uint32 duv = N->t.t - Rt;
                uint32 du = tmp * int16(duv >> 16);
                uint32 dv = tmp * int16(duv);
                Rdt = (du & 0xFFFF0000) | (dv >> 16);
            }

            Rx <<= 16;
            Rg <<= 8;
            R = N;
        }

        int32 h = X_MIN(Lh, Rh);
        Lh -= h;
        Rh -= h;

    #ifdef ALIGNED_LIGHTMAP
        Lg |= intptr_t(lightmap);
        Rg |= intptr_t(lightmap);
    #endif

        while (h--)
        {
            int32 x1 = Lx >> 16;
            int32 x2 = Rx >> 16;

            int32 width = x2 - x1;

            if (width > 0)
            {
                int32 tmp = FixedInvU(width);

                int32 dgdx = tmp * (Rg - Lg) >> 15;

                uint32 duv = Rt - Lt;
                uint32 u = tmp * int16(duv >> 16);
                uint32 v = tmp * int16(duv);
                uint32 dtdx = (u & 0xFFFF0000) | (v >> 16);

                int32 g = Lg;
                uint32 t = Lt;

                uint8* ptr = (uint8*)pixel + x1;

                if (intptr_t(ptr) & 1)
                {
                    uint8 indexA = tile[(t & 0xFF00) | (t >> 24)];
                    if (indexA) {
                #ifdef ALIGNED_LIGHTMAP
                        const uint8* LMAP = (uint8*)(g >> 8 << 8);
                        ptr[0] = LMAP[indexA];
                #else
                        ptr[0] = lightmap[(g >> 8 << 8) | indexA];
                #endif
                    }
                    ptr++;
                    t += dtdx;
                    g += dgdx >> 1;
                    width--;
                }

                if (width & 1)
                {
                    uint32 tmp = Rt - dtdx;
                    uint8 indexA = tile[(tmp & 0xFF00) | (tmp >> 24)];
                    if (indexA) {
                #ifdef ALIGNED_LIGHTMAP
                        const uint8* LMAP = (uint8*)(Rg >> 8 << 8);
                        ptr[width - 1] = LMAP[indexA];
                #else
                        ptr[width - 1] = lightmap[(Rg >> 8 << 8) | indexA];
                #endif
                    }
                }

                width >>= 1;

            #ifdef TEX_2PX
                dtdx <<= 1;
                while (width--)
                {
                    uint8 indexA = tile[(t & 0xFF00) | (t >> 24)];
                    if (indexA) {
                #ifdef ALIGNED_LIGHTMAP
                        const uint8* LMAP = (uint8*)(g >> 8 << 8);
                        indexA = LMAP[indexA];
                #else
                        indexA = lightmap[(g >> 8 << 8) | indexA];
                #endif
                        *(uint16*)ptr = indexA | (indexA << 8);
                    }
                    ptr += 2;
                    t += dtdx;
                    g += dgdx;
                }
            #else
                while (width--)
                {
                    uint8 indexA = tile[(t & 0xFF00) | (t >> 24)];
                    t += dtdx;
                    uint8 indexB = tile[(t & 0xFF00) | (t >> 24)];
                    t += dtdx;
                    g += dgdx;
                    if (indexA && indexB) {
                #ifdef ALIGNED_LIGHTMAP
                        const uint8* LMAP = (uint8*)(g >> 8 << 8);
                #else
                        const uint8* LMAP = &lightmap[g >> 8 << 8];
                #endif
                        *(uint16*)ptr = LMAP[indexB] | (LMAP[indexA] << 8);
                    }

                    ptr += 2;
                }
            #endif
            }

            pixel += (FRAME_WIDTH >> 1);

            Lx += Ldx;
            Rx += Rdx;
            Lg += Ldg;
            Rg += Rdg;
            Lt += Ldt;
            Rt += Rdt;
        }
    }
}

X_NOINLINE void rasterizeLineH_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    R++;
    int32 x = L->v.x;
    int32 index = L->v.g;
    int32 width = R->v.x;

    uint8* ptr = (uint8*)pixel + x;

    if (intptr_t(ptr) & 1)
    {
        *ptr++ = index;
        width--;
    }

    if (width & 1)
    {
        width--;
        ptr[width] = index;
    }

    index |= (index << 8);

    for (int32 i = 0; i < width / 2; i++)
    {
        *(uint16*)ptr = index;
        ptr += 2;
    }
}

X_NOINLINE void rasterizeLineV_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    R++;
    int32 x = L->v.x;
    int32 index = L->v.g;
    int32 height = R->v.y;

    uint8* ptr = (uint8*)pixel + x;

    for (int32 i = 0; i < height; i++)
    {
        *ptr = index;
        ptr += FRAME_WIDTH;
    }
}

X_NOINLINE void rasterizeFillS_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    R++;
    int32 x = L->v.x;
    int32 shade = L->v.g;
    int32 width = R->v.x;
    int32 height = R->v.y;

    const uint8* lm = &gLightmap[shade << 8];

    for (int32 i = 0; i < height; i++)
    {
        uint8* ptr = (uint8*)pixel + x;
        int32 w = width;

        if (intptr_t(ptr) & 1)
        {
            ptr[0] = lm[ptr[0]];
            ptr++;
            w--;
        }

        if (w & 1)
        {
            w--;
            ptr[w] = lm[ptr[w]];
        }

        for (int32 i = 0; i < w / 2; i++)
        {
            uint16 p = *(uint16*)ptr;
            *(uint16*)ptr = lm[p & 0xFF] | (lm[p >> 8] << 8);
            ptr += 2;
        }

        pixel += FRAME_WIDTH / 2;
    }
}
#endif

X_NOINLINE void rasterizeSprite_c(uint16* pixel, const VertexLink* L, const VertexLink* R)
{
    R++;
    const uint8* ft_lightmap = &gLightmap[L->v.g << 8];
    const uint8* tile = gTile;

    int32 w = R->v.x - L->v.x;
    if (w <= 0 || w >= DIV_TABLE_SIZE) return;

    int32 h = R->v.y - L->v.y;
    if (h <= 0 || h >= DIV_TABLE_SIZE) return;

    int32 u = L->t.uv.v;
    int32 v = L->t.uv.u;

    int32 iw = FixedInvU(w);
    int32 ih = FixedInvU(h);

    int32 du = R->t.uv.v * iw >> 8;
    int32 dv = R->t.uv.u * ih >> 8;

    if (L->v.y < 0)
    {
        pixel -= L->v.y * (FRAME_WIDTH >> 1);
        v -= L->v.y * dv;
        h += L->v.y;
    }

    if (R->v.y > FRAME_HEIGHT)
    {
        h -= R->v.y - FRAME_HEIGHT;
    }

    uint8* ptr = (uint8*)pixel;

    if (h <= 0) return;

    ptr += L->v.x;

    if (L->v.x < 0)
    {
        ptr -= L->v.x;
        u -= L->v.x * du;
        w += L->v.x;
    }

    if (R->v.x > FRAME_WIDTH)
    {
        w -= R->v.x - FRAME_WIDTH;
    }

    if (w <= 0) return;

    while (h--)
    {
        const uint8* xtile = tile + (v & 0xFF00);

        uint8* xptr = ptr;

        int32 xu = u;

        for (int32 x = 0; x < w; x++)
        {
            uint8 indexB = xtile[xu >> 8];//indexB = 255;
            xu += du;
            if (indexB) xptr[0] = ft_lightmap[indexB];
            xptr++;
        }

        v += dv;

        ptr += FRAME_WIDTH;
    }
}

#endif
