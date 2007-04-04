/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static HV *package_stash;

#if defined(INTEGER64_BACKEND_DOUBLE)

int
SvI64OK(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *si64 = SvRV(sv);
        return (si64 && SvNOK(si64) && sv_isa(sv, "Math::Int64"));
    }
    return 0;
}

SV *
newSVi64(pTHX_ int64_t i64) {
    SV *sv;
    SV *si64 = newSVnv(0);
    *(int64_t*)(&(SvNVX(si64))) = i64;
    sv = newRV_noinc(si64);
    sv_bless(sv, package_stash);
    return sv;
}

#define SvI64X(sv) (*(int64_t*)(&(SvNVX(SvRV(sv)))))

SV *
SvSI64(pTHX_ SV *sv) {
    if (SvRV(sv)) {
        SV *si64 = SvRV(sv);
        if (si64 && SvNOK(si64))
            return si64;
    }
    Perl_croak(aTHX_ "internal error: reference to NV expected");
}

#define SvI64x(sv) (*(int64_t*)(&(SvNVX(SvSI64(aTHX_ sv)))))

int64_t
SvI64(pTHX_ SV *sv) {
    if (!SvOK(sv)) {
        return 0;
    }
    if (SvUOK(sv)) {
        return SvUV(sv);
    }
    if (SvIOK(sv)) {
        return SvIV(sv);
    }
    if (SvNOK(sv)) {
        return SvNV(sv);
    }
    if (SvROK(sv)) {
        SV *si64 = SvRV(sv);
        if (si64 && SvNOK(si64) && sv_isa(sv, "Math::Int64")) {
            return *(int64_t*)(&(SvNVX(si64)));
        }
    }
    return atoll(SvPV_nolen(sv));
    /* return parse_i64(aTHX_ sv); */
}

SV *
si64_to_number(pTHX_ SV *sv) {
    int64_t i64 = SvI64x(sv);
    IV iv;
    UV uv;
    uv = i64;
    if (uv == i64)
        return newSVuv(uv);
    iv = i64;
    if (iv == i64)
        return newSViv(iv);
    return newSVnv(i64);
}

#elif defined(INTEGER64_BACKEND_STRING)

#elif defined(INTEGER64_BACKEND_NATIVE)

#endif


MODULE = Math::Int64		PACKAGE = Math::Int64		PREFIX=my_
PROTOTYPES: DISABLE

BOOT:
package_stash = gv_stashsv(newSVpv("Math::Int64", 0), 1);

SV *
my_int64(value=&PL_sv_undef)
    SV *value;
CODE:
    RETVAL = newSVi64(aTHX_ SvI64(aTHX_ value));
OUTPUT:
    RETVAL

SV *
my_inc(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    SvI64x(self)++;
    RETVAL = self;
    SvREFCNT_inc(RETVAL);
OUTPUT:
    RETVAL

SV *
my_dec(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    SvI64x(self)--;
    RETVAL = self;
    SvREFCNT_inc(RETVAL);
OUTPUT:
    RETVAL

SV *
my_add(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    /*
    fprintf(stderr, "self: ");
    sv_dump(self);
    fprintf(stderr, "other: ");
    sv_dump(other);
    fprintf(stderr, "rev: ");
    sv_dump(rev);
    fprintf(stderr, "\n");
    */
    if (SvOK(rev)) 
        RETVAL = newSVi64(aTHX_ SvI64x(self) + SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) += SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_sub(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_
                          SvTRUE(rev)
                          ? SvI64(aTHX_ other) - SvI64x(self)
                          : SvI64x(self) - SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) -= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_mul(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) * SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) *= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_div(self, other, rev)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t up;
    int64_t down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvI64(aTHX_ other);
            down = SvI64x(self);
        }
        else {
            up = SvI64x(self);
            down = SvI64(aTHX_ other);
        }
        if (!down)
            Perl_croak(aTHX_ "Illegal division by zero");
        RETVAL = newSVi64(aTHX_ up/down);
    }
    else {
        down = SvI64(aTHX_ other);
        if (!down)
            Perl_croak(aTHX_ "Illegal division by zero");
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) /= down;
    }
OUTPUT:
    RETVAL

SV *
my_rest(self, other, rev)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t up;
    int64_t down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvI64(aTHX_ other);
            down = SvI64x(self);
        }
        else {
            up = SvI64x(self);
            down = SvI64(aTHX_ other);
        }
        if (!down)
            Perl_croak(aTHX_ "Illegal division by zero");
        RETVAL = newSVi64(aTHX_ up % down);
    }
    else {
        down = SvI64(aTHX_ other);
        if (!down)
            Perl_croak(aTHX_ "Illegal division by zero");
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) %= down;
    }
OUTPUT:
    RETVAL

SV *my_left(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_
                          SvTRUE(rev)
                          ? SvI64(aTHX_ other) << SvI64x(self)
                          : SvI64x(self) << SvI64(aTHX_ other) );
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) <<= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *my_right(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_
                          SvTRUE(rev)
                          ? SvI64(aTHX_ other) >> SvI64x(self)
                          : SvI64x(self) >> SvI64(aTHX_ other) );
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) >>= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

int
my_spaceship(self, other, rev)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t left;
    int64_t right;
CODE:
    if (SvTRUE(rev)) {
        left = SvI64(aTHX_ other);
        right = SvI64x(self);
    }
    else {
        left = SvI64x(self);
        right = SvI64(aTHX_ other);
    }
    RETVAL = (left < right ? -1 : left > right ? 1 : 0);
OUTPUT:
    RETVAL

SV *
my_eqn(self, other, rev)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvI64x(self) == SvI64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_undef );
OUTPUT:
    RETVAL

SV *
my_nen(self, other, rev)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvI64x(self) != SvI64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_no );
OUTPUT:
    RETVAL

SV *
my_gtn(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) < SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
    else
        RETVAL = SvI64x(self) > SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
my_ltn(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) > SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
    else
        RETVAL = SvI64x(self) < SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
my_gen(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) <= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
    else
        RETVAL = SvI64x(self) >= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
my_len(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) >= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
    else
        RETVAL = SvI64x(self) <= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
my_and(self, other, rev)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) & SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) &= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_or(self, other, rev)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) | SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) |= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_xor(self, other, rev)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) ^ SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) ^= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
my_not(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvI64x(self) ? &PL_sv_undef : &PL_sv_yes;
OUTPUT:
    RETVAL

SV *
my_bnot(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ ~SvI64x(self));
OUTPUT:
    RETVAL    

SV *
my_neg(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ -SvI64x(self));
OUTPUT:
    RETVAL

SV *
my_bool(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvI64x(self) ? &PL_sv_yes : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
my_number(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = si64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
my_int64_to_number(self)
    SV *self
CODE:
    RETVAL = si64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
my_net_to_int64(net)
    SV *net;
PREINIT:
    STRLEN len;
    char *pv = SvPV(net, len);
CODE:
    if (len != 8)
        Perl_croak(aTHX_ "Invalid length for int64");
    RETVAL = newSVi64(aTHX_
                      (((((((((((((((int64_t)pv[0]) << 8)
                                  + (int64_t)pv[1]) << 8)
                                  + (int64_t)pv[2]) << 8)
                                  + (int64_t)pv[3]) << 8)
                                  + (int64_t)pv[4]) << 8)
                                  + (int64_t)pv[5]) << 8)
                                  + (int64_t)pv[6]) <<8)
                                  + (int64_t)pv[7]);
OUTPUT:
    RETVAL

SV *
my_int64_to_net(self)
    SV *self
PREINIT:
    char *pv;
    int64_t i64 = SvI64x(self);
    int i;
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    pv[8] = '\0';
    for (i = 7; i >= 0; i--, i64 >>= 8)
        pv[i] = i64;
OUTPUT:
    RETVAL

SV *
my_native_to_int64(native)
    SV *native
PREINIT:
    STRLEN len;
    char *pv = SvPV(native, len);
CODE:
    if (len != 8)
        Perl_croak(aTHX_ "Invalid length for int64");
    RETVAL = newSVi64(aTHX_ 0);
    Copy(pv, &(SvI64X(RETVAL)), 8, char);
OUTPUT:
    RETVAL

SV *
my_int64_to_native(self)
    SV *self
PREINIT:
    char *pv;
    int64_t i64 = SvI64(aTHX_ self);
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    Copy(&i64, pv, 8, char);
OUTPUT:
    RETVAL

SV *
my_clone(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ SvI64x(self));
OUTPUT:
    RETVAL

SV *
my_string(self, other, rev)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
PREINIT:
    STRLEN len;
CODE:
    RETVAL = newSV(22);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, sprintf(SvPVX(RETVAL), "%lli", SvI64x(self)));
OUTPUT:
    RETVAL








    
