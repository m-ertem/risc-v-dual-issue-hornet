**IMPROVING INSTRUCTION THROUGHPUT OF A RISC-V CORE USING PIPELINE DOUBLING**
<br/>This study aims to upgrade the single-issue RV32IM RISC-V core Hornet to dual-issue architecture.
<br/>It has been studied as a graduation thesis in Istanbul Technical University
<br/>https://web.itu.edu.tr/~orssi/thesis/2024/AykutKilic_bit.pdf
<br/>The resulting RISC-V core has following performance improvements:

|RV32IM|Hornet (Cycles)|Dual-issue (Cycles)|Improvement(%)|
|---|---|
| Bubble Sort | 282 | 195 | 44.6 |
| Soft Float | 1221 | 1016 | 20.2 |
| Muldiv | 2928 | 2721 | 7.6 |
| AES | 4866 | 3493 | 39.3 |
