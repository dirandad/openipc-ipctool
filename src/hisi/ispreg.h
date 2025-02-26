#ifndef HISI_ISPREG_H
#define HISI_ISPREG_H

#include <stdint.h>
#include <stdbool.h>

#define CV300_CRG_BASE 0x12010000
#define CV300_PERI_CRG11_ADDR CV300_CRG_BASE + 0x002c

struct EV300_PERI_CRG60 {
    bool sensor0_cken : 1;
    unsigned int sensor0_srst_req : 1;
    unsigned int sensor0_cksel : 3;
    bool sensor0_ctrl_cken : 1;
    unsigned int sensor0_ctrl_srst_req : 1;
};

#define EV300_PERI_CRG60_ADDR 0x120100F0

#endif /* HISI_ISPREG_H */
