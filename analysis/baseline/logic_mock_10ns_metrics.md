# Logic-Mock 10 ns Physical Design Baseline Report

> **Project:** MNIST DNN ASIC Physical Design
> **Top module:** `mnist_dnn_pd_top`
> **Variant:** `logic_mock_10ns`
> **Platform:** Sky130HD
> **Status:** RTL-to-GDS flow completed; post-route baseline metrics extracted

---

## 1. Report scope

This document records the first complete post-route physical-design baseline for the
MNIST DNN RTL.

The verified RTL was mapped to Sky130HD standard cells and processed through:

```text
Synthesis
→ Floorplan / PDN
→ Placement
→ Clock Tree Synthesis
→ Global Routing
→ Detailed Routing
→ SPEF RC Extraction
→ Post-route Static Timing Analysis
→ Final ODB / DEF / GDS generation
```

This run is intentionally a **logic-only baseline**. Large inferred weight memories
were mocked so that the compute/control logic could complete the full physical-design
flow without exploding the memories into an impractical number of standard cells.

---

## 2. Run configuration

| Item | Value |
|---|---|
| Design name | `mnist_dnn_pd` |
| Top module | `mnist_dnn_pd_top` |
| Flow variant | `logic_mock_10ns` |
| Platform | Sky130HD |
| Standard-cell library | `sky130_fd_sc_hd` |
| Timing corner | TT, 25 °C, 1.80 V |
| OpenROAD version | `26Q3-318-g6b9d7fb806` |
| Threads | 8 |
| Target clock | `core_clock` |
| Clock period | 10.00 ns |
| Nominal target frequency | 100 MHz |
| Core utilization setting | 40% |
| Placement density setting | 0.55 |
| Large memory handling | Mock memories enabled |
| Large-memory threshold | 4,096 bits |
| LEC | Disabled (`LEC_CHECK=0`) |
| Post-route parasitics | SPEF loaded |
| Final database | `6_final.odb` |

---

## 3. Executive summary

| Category | Metric | Result | Status |
|---|---|---:|---|
| Timing | Target clock period | 10.00 ns | — |
| Timing | Target frequency | 100 MHz | — |
| Timing | Worst setup slack | **+4.20 ns** | PASS |
| Timing | Setup WNS | **0.00 ns** | PASS |
| Timing | Setup TNS | **0.00 ns** | PASS |
| Timing | Worst hold slack | **+0.25 ns** | PASS |
| Timing | Minimum clock period | **5.80 ns** | PASS |
| Timing | Reported Fmax | **172.30 MHz** | — |
| Clock | Setup clock skew | **0.14 ns** | PASS |
| Area | Logic/design area | **67,417 µm²** | — |
| Area | Final utilization | **45%** | — |
| Area | Core area | **149,776.15 µm²** | — |
| Area | Die area | **166,606.83 µm²** | — |
| Power | Total estimated power | **10.7 mW** | Preliminary |
| Routing | Detailed-route wirelength | **148.405 mm** | — |
| Antenna | Net violations | **0** | PASS |
| Antenna | Pin violations | **0** | PASS |
| DRC | Detailed-route DRC | **0 errors from ORFS route metrics** | PASS |
| Memory | Memory-inclusive PPA | Not included | LIMITATION |

### Baseline verdict

The `logic_mock_10ns` design completed post-route implementation and meets both
setup and hold timing at 100 MHz. The timing margin is large at the target frequency,
and the post-route minimum-period report indicates a theoretical limit of approximately
172.3 MHz under the current TT/25 °C/1.80 V analysis condition.

The result is suitable as the **compute/control physical-design baseline** for future
clock, utilization and placement-density sweeps. It is not a final memory-inclusive
chip PPA result.

---

# 4. Timing analysis

## 4.1 Timing summary

| Metric | Result | Pass condition | Verdict |
|---|---:|---:|---|
| Clock period | 10.00 ns | Constraint | — |
| Target frequency | 100 MHz | Constraint | — |
| Worst setup slack | **+4.20 ns** | `>= 0 ns` | PASS |
| Setup WNS | **0.00 ns** | `0 ns` when no negative slack | PASS |
| Setup TNS | **0.00 ns** | `0 ns` | PASS |
| Worst hold slack | **+0.25 ns** | `>= 0 ns` | PASS |
| Minimum clock period | **5.80 ns** | — | — |
| Reported Fmax | **172.30 MHz** | — | — |
| Setup clock skew | **0.14 ns** | Minimize | PASS |
| Clock uncertainty | 0.10 ns | Constraint | — |

### Interpretation

- `report_worst_slack` returned `+4.20 ns`, so the slowest setup path completes
  with substantial margin at a 10 ns period.
- `report_wns` and `report_tns` both returned `0.00 ns`. This means there are no
  negative-slack setup paths.
- The worst hold path has `+0.25 ns` slack. Hold timing passes, but its margin is
  considerably smaller than the setup margin and must be monitored in future
  placement and CTS experiments.
- The minimum-period report returned `5.80 ns`, equivalent to `172.30 MHz`.
  This is a report-based estimate for the current routed implementation and analysis
  corner, not a guarantee across all PVT corners.

---

## 4.2 Worst setup path

| Item | Result |
|---|---|
| Path group | `core_clock` |
| Path type | Max / Setup |
| Startpoint | `u_mnist_dnn.u_layer3.u_weight_rom.data_out[7]$_DFF_P_` |
| Endpoint | `u_mnist_dnn.u_layer3.u_dense_engine.output_acc[28]$_DFFE_PN0P_` |
| Functional interpretation | Layer 3 weight sign bit → signed MAC / accumulator upper bit |
| Data arrival time | 6.33 ns |
| Data required time | 10.53 ns |
| Slack | **+4.20 ns (MET)** |
| Launch clock latency | approximately 0.75 ns |
| Capture clock latency | approximately 0.76 ns |
| Path-local launch/capture latency difference | approximately +0.01 ns |
| Clock uncertainty | 0.10 ns |
| Endpoint setup time | 0.13 ns |

### Path structure

The critical path begins at bit 7 of the Layer 3 weight output. Since the weight is
signed, bit 7 is the sign bit and drives sign-extension and arithmetic logic.

The reported path contains:

```text
Weight output flip-flop
→ inserted drive-strength buffer
→ sign/control logic
→ five full-adder stages
→ one half-adder stage
→ AOI/OAI/NAND logic
→ accumulator update multiplexer/control logic
→ output_acc[28] flip-flop
```

A timing-repair buffer (`sky130_fd_sc_hd__buf_4`) was inserted on the weight sign-bit
net, which has a reported fanout of 26. This indicates that signed extension and
arithmetic use create a relatively high load on the sign bit.

The arithmetic chain dominates the delay:

- Full-adder cell delays are approximately 0.42–0.54 ns each.
- The full-/half-adder portion grows from about 1.60 ns to 4.32 ns.
- Additional AOI/OAI and mux logic extends the path to the final 6.33 ns arrival.

Most net increments in the printed path are approximately 0.00–0.01 ns, while
individual cell delays are much larger. Therefore, this critical path is primarily
**logic-depth limited**, not wire-delay limited.

### Conclusion for the setup path

> The first baseline identifies the Layer 3 signed MAC datapath—specifically the
> weight sign-bit to accumulator upper-bit path—as the post-route setup bottleneck.

Because the weight memory is mocked, the memory access delay itself is not realistic.
The meaningful part of this result is the compute path after the mocked weight output.

---

## 4.3 Worst hold path

| Item | Result |
|---|---|
| Path group | `core_clock` |
| Path type | Min / Hold |
| Startpoint | `u_mnist_dnn.u_layer2.u_dense_engine.state[5]$_DFF_PN0_` |
| Endpoint | `u_mnist_dnn.u_layer2.u_dense_engine.state[1]$_DFF_PN0_` |
| Functional interpretation | Layer 2 Dense Engine state-register path |
| Data arrival time | 1.06 ns |
| Data required time | 0.81 ns |
| Hold slack | **+0.25 ns (MET)** |
| Launch clock latency | approximately 0.74 ns |
| Capture clock latency | approximately 0.74 ns |
| Library hold time | approximately -0.03 ns |
| Clock uncertainty | 0.10 ns |

The path is essentially a direct register-to-register state path:

```text
state[5] flip-flop Q
→ short net
→ state[1] flip-flop D
```

There is almost no combinational delay between the registers, which is why this path
is the most hold-sensitive path. It passes with `+0.25 ns`, but this margin may change
when clock-tree structure, utilization, placement density or timing-repair settings
are modified.

---

## 4.4 Clock skew

| Metric | Result |
|---|---:|
| Reported setup skew | **0.14 ns** |
| Fraction of 10 ns period | **1.4%** |
| Clock uncertainty used | 0.10 ns |

The standalone clock-skew report identifies a source latency of approximately
0.77 ns and target latency of approximately 0.73 ns, with uncertainty included in the
reported 0.14 ns setup-skew value.

At 100 MHz, the skew is small relative to the clock period. In future higher-frequency
runs, the same absolute skew will consume a larger fraction of the available timing
budget.

---

## 4.5 Setup slack distribution

| Slack range | Reported endpoints |
|---:|---:|
| 4.196–4.720 ns | 45 |
| 4.720–5.245 ns | 76 |
| 5.245–5.769 ns | 22 |
| 5.769–6.293 ns | 32 |
| 6.293–6.818 ns | 864 |
| 6.818–7.342 ns | 107 |
| 7.342–7.866 ns | 614 |
| 7.866–8.391 ns | 202 |
| 8.391–8.915 ns | 8 |
| 8.915–9.439 ns | 10 |
| **Total** | **1,980** |

The worst reported setup slack is approximately 4.196 ns, consistent with the
rounded `+4.20 ns` summary. Most endpoints are concentrated in the
6.293–6.818 ns and 7.342–7.866 ns bins.

---

## 4.6 Hold slack distribution

| Slack range | Reported endpoints |
|---:|---:|
| 0.247–0.628 ns | 292 |
| 0.628–1.009 ns | 176 |
| 1.009–1.390 ns | 1,400 |
| 1.390–1.771 ns | 62 |
| 1.771–2.152 ns | 1 |
| 2.152–2.533 ns | 0 |
| 2.533–2.914 ns | 0 |
| 2.914–3.295 ns | 0 |
| 3.295–3.677 ns | 47 |
| 3.677–4.058 ns | 2 |
| **Total** | **1,980** |

All printed hold-slack bins are positive. The worst bin begins at approximately
0.247 ns, consistent with the rounded `+0.25 ns` worst hold slack.

---

## 4.7 Logic-depth distribution

| Logic-depth range | Reported paths |
|---:|---:|
| 0–2 | 463 |
| 3–5 | 58 |
| 6–8 | 763 |
| 9–11 | 87 |
| 12–14 | 915 |
| 15–17 | 63 |
| 18–20 | 36 |
| 21–23 | 58 |
| 24–26 | 0 |
| 27–30 | 0 |
| **Total** | **2,443** |

The largest population is in the 12–14 logic-level range. The report also contains
58 paths in the 21–23 level range, but no reported paths at 24 levels or above.
The worst setup path is consistent with a relatively deep arithmetic/control chain.

---

# 5. Area and geometry

## 5.1 Geometry summary

| Metric | Result |
|---|---:|
| Die coordinates | `(0.0, 0.0)` to `(408.175, 408.175)` µm |
| Die width | 408.175 µm |
| Die height | 408.175 µm |
| Die area | **166,606.83 µm²** |
| Die area | **0.166607 mm²** |
| Core coordinates | `(10.12, 10.88)` to `(397.9, 397.12)` µm |
| Core width | 387.78 µm |
| Core height | 386.24 µm |
| Core area | **149,776.15 µm²** |
| Core area | **0.149776 mm²** |
| Logic/design area | **67,417 µm²** |
| Logic/design area | **0.067417 mm²** |
| Final utilization | **45%** |
| Initial utilization setting | 40% |

### Interpretation

The configured initial core utilization was 40%, while the final report shows 45%.
The increase is expected after placement optimization, timing repair, CTS and the
insertion of physical/tie-related cells.

The `report_cell_usage` total area equals the full core area because fill cells occupy
unused legal row area. Therefore:

- `67,417 µm²` is the meaningful placed design area reported for utilization.
- `149,776.15 µm²` is the total core footprint.
- The fill-cell area must not be counted as functional logic area.

---

## 5.2 Cell usage

| Cell category | Count | Area (µm²) | Interpretation |
|---|---:|---:|---|
| Fill cells | 13,381 | 82,358.99 | Physical row filling; not functional logic |
| Tap cells | 2,016 | 2,522.42 | Well/substrate connection |
| Antenna cells | 1 | 2.50 | Antenna repair/protection |
| Clock buffers | 167 | 3,492.10 | CTS clock distribution |
| Timing-repair buffers | 159 | 1,358.80 | Timing/fanout repair |
| Inverters | 153 | 574.30 | Logic/timing |
| Clock inverters | 70 | 872.09 | Clock distribution |
| Sequential cells | 1,163 | 32,687.60 | Flip-flops/register-based storage |
| Multi-input combinational cells | 3,218 | 25,907.35 | Arithmetic/control logic |
| **Total physical instances** | **20,328** | **149,776.15** | Includes fill and tap cells |

### Derived counts

| Derived metric | Result |
|---|---:|
| Non-fill instances | 6,947 |
| Functional/clock/timing instances excluding fill, tap and antenna | 4,930 |
| Clock buffer + clock inverter count | 237 |
| Clock/timing regular buffer count | 326 |

### Interpretation

- Fill cells account for the majority of physical instance count, but they are not
  functional logic.
- Sequential cells occupy approximately half of the reported functional design area.
- The 167 clock buffers and 70 clock inverters are consistent with the relatively high
  clock-power contribution.
- The design contains a substantial amount of register-based storage because the
  current flow does not include real SRAM/ROM macros.

---

# 6. Power analysis

## 6.1 Total power

| Component | Result |
|---|---:|
| Internal power | **8.23 mW** |
| Switching power | **2.49 mW** |
| Leakage power | **22.7 nW** |
| Total power | **10.7 mW** |

| Power type | Share |
|---|---:|
| Internal | 76.8% |
| Switching | 23.2% |
| Leakage | approximately 0.0% |

---

## 6.2 Power by cell group

| Group | Internal | Switching | Leakage | Total | Share |
|---|---:|---:|---:|---:|---:|
| Sequential | 5.14 mW | 0.0597 mW | 10.2 nW | **5.20 mW** | **48.5%** |
| Combinational | 0.311 mW | 0.386 mW | 10.4 nW | **0.697 mW** | **6.5%** |
| Clock | 2.78 mW | 2.04 mW | 2.12 nW | **4.82 mW** | **45.0%** |
| Macro | 0 | 0 | 0 | **0** | 0.0% |
| Pad | 0 | 0 | 0 | **0** | 0.0% |
| **Total** | **8.23 mW** | **2.49 mW** | **22.7 nW** | **10.7 mW** | **100%** |

### Interpretation

Sequential and clock groups together account for:

```text
48.5% + 45.0% = 93.5% of total reported power
```

The clock network alone accounts for 45% of the total estimate. This is an important
optimization target for future experiments, but the absolute value must be treated
cautiously because the power activity was not derived from a real inference workload.

---

## 6.3 Activity-annotation limitation

The activity report identified:

```text
18,918 unannotated pins
```

This includes top-level ports and a large number of internal pins. Therefore, the
`10.7 mW` result is a **vectorless/default-activity estimate**, not a simulation-based
workload power measurement.

Consequences:

- Absolute power and energy-per-inference must not be claimed from this report.
- The value is useful primarily as a first baseline and for relative comparisons
  between physical-design variants that use the same activity assumptions.
- A later power study should annotate switching activity from VCD or SAIF generated
  by a representative MNIST inference simulation.

---

# 7. Routing analysis

## 7.1 Detailed-route wirelength

| Layer | Wirelength | Reported share |
|---|---:|---:|
| `met1` | 62,338.54 µm | 42% |
| `met2` | 68,388.51 µm | 46% |
| `met3` | 13,450.95 µm | 9% |
| `met4` | 4,227.40 µm | 2% |
| **Total** | **148,405.40 µm** | approximately 100% |
| **Total** | **148.405 mm** | — |

### Derived routing observations

| Observation | Result |
|---|---:|
| `met1 + met2` wirelength | 130,727.05 µm |
| Lower-layer (`met1 + met2`) share | approximately 88.1% |
| `met3 + met4` wirelength | 17,678.35 µm |
| Upper reported routing-layer share | approximately 11.9% |

Most signal routing is concentrated in `met1` and `met2`, indicating that the current
logic-only design is dominated by local and medium-distance cell-to-cell connections.
The detailed-route summary printed signal routing on `met1` through `met4`. This does
not prove that higher layers are absent from the power grid or other special routing.

---

# 8. Physical verification

## 8.1 Antenna check

| Metric | Result | Verdict |
|---|---:|---|
| Net antenna violations | **0** | PASS |
| Pin antenna violations | **0** | PASS |
| Antenna cells inserted | 1 | — |

The antenna checker reported no remaining net or pin violations.

---

## 8.2 Detailed-route DRC

The attempted GUI Tcl command returned:

```text
COMMAND_ERROR: invalid command name "check_drc"
```

Therefore, a detailed-route DRC count was **not obtained from that GUI Tcl capture**.

However, the ORFS detailed-route metrics file records the final detailed-route DRC
count as zero:

```text
logs/sky130hd/mnist_dnn_pd/logic_mock_10ns/5_2_route.json
detailedroute__route__drc_errors = 0
```

The routing log also shows the detailed router reducing intermediate violations to
zero before completing detailed routing. A later sign-off-oriented archive should
still keep the GUI/DRC-viewer evidence or the supported OpenROAD DRC report command
output together with this JSON metric.

| Check | Status |
|---|---|
| Antenna | PASS |
| Setup timing | PASS |
| Hold timing | PASS |
| Detailed-route DRC | **0 errors in ORFS detailed-route metrics** |
| Final routed database | Generated and loaded |
| SPEF extraction | Loaded for post-route STA |

---

# 9. Consolidated baseline row

The following row should be used as the first entry in later sweep comparisons.

| Variant | Period | Target | Min period | Fmax | Setup slack | Setup WNS/TNS | Hold slack | Skew | Design area | Core util. | Power | Wirelength | Antenna | DRC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `logic_mock_10ns` | 10.00 ns | 100 MHz | 5.80 ns | 172.30 MHz | +4.20 ns | 0 / 0 ns | +0.25 ns | 0.14 ns | 67,417 µm² | 45% | 10.7 mW* | 148.405 mm | 0 net / 0 pin | 0 |

\* Power is vectorless/default-activity, logic-only, and memory-mock based.

---

# 10. Main engineering conclusions

## 10.1 Timing closure

The design closes both setup and hold timing at 100 MHz:

```text
Setup worst slack = +4.20 ns
Hold worst slack  = +0.25 ns
Setup WNS/TNS     = 0 / 0 ns
```

The 10 ns target is conservative for this logic-only baseline. The report-based
minimum period is 5.80 ns, but future runs should reduce the clock period gradually
rather than immediately treating 172.3 MHz as a guaranteed operating frequency.

---

## 10.2 Critical-path bottleneck

The setup bottleneck is located in the Layer 3 signed MAC path:

```text
weight sign bit
→ high-fanout buffer
→ signed arithmetic
→ full-/half-adder chain
→ accumulator update control
→ accumulator register
```

Cell delay dominates over wire delay. Therefore, logic structure and cell mapping are
more important than pure wirelength for this specific critical path.

---

## 10.3 Hold sensitivity

The hold-critical path is a nearly direct Layer 2 state-register path. Because it has
almost no combinational delay, it is sensitive to clock-tree latency differences and
future placement changes.

Clock-period reduction primarily stresses setup timing, but utilization, placement
density and CTS changes may alter the hold result. Hold timing must therefore be
checked after every full-flow experiment.

---

## 10.4 Clock and power

The reported setup skew is 0.14 ns, which is small at a 10 ns period. However, the
clock group contributes 45% of total estimated power, and clock-related cells include
167 clock buffers and 70 clock inverters.

The high clock-power share is a major observation, although absolute power conclusions
must wait for real activity annotation and realistic memory macros.

---

## 10.5 Area

The final logic/design area is 67,417 µm² inside a 149,776 µm² core, producing 45%
utilization. The initial 40% target increased after optimization, CTS and physical-cell
insertion.

The reported 20,328 total cells include 13,381 fill cells and 2,016 tap cells. These
must not be mistaken for functional logic.

---

## 10.6 Routing

The total detailed signal-route wirelength is approximately 148.405 mm. About 88% is
on `met1` and `met2`, so the design is dominated by lower-layer local routing.
No antenna violations remain.

A routing-congestion heat map and GUI-visible DRC evidence should still be archived
for a complete physical-quality assessment.

---

# 11. Limitations

## 11.1 Mocked weight memories

Large inferred weight memories were mocked:

```makefile
SYNTH_MEMORY_MAX_BITS = 4096
SYNTH_MOCK_LARGE_MEMORIES = 1
```

Therefore, this report does **not** include realistic:

- Weight-ROM area
- Memory access delay
- Memory switching/leakage power
- Memory macro placement
- Macro blockage and pin-access congestion
- Memory-inclusive critical path
- Full-chip memory-inclusive PPA

---

## 11.2 LEC disabled

`LEC_CHECK=0` was used because the available LEC executable caused an illegal
instruction on the host CPU.

Functional confidence currently comes from the original RTL/cocotb bit-exact
verification and successful flow completion. A future sign-off-oriented run should
restore formal equivalence or perform an alternative gate-level equivalence check.

---

## 11.3 Power is not workload annotated

There were 18,918 unannotated pins. The current power report is suitable only for
same-assumption relative comparisons.

---

## 11.4 Single timing corner

Timing was analyzed at:

```text
TT / 25 °C / 1.80 V
```

No slow/fast corner, voltage variation or temperature sweep has yet been performed.
The reported 172.30 MHz must therefore not be described as a sign-off Fmax.

---

## 11.5 DRC command limitation

The `check_drc` Tcl command was unsupported in this OpenROAD build. The current
document therefore uses the ORFS detailed-route metrics JSON as the DRC evidence:

```text
detailedroute__route__drc_errors = 0
```

For a stronger sign-off package, archive the corresponding GUI DRC-viewer evidence or
the equivalent supported OpenROAD report command output.

---

# 12. Recommended next experiments

The first baseline is now sufficiently characterized to begin controlled sweeps.
Only one physical variable should be changed at a time.

## 12.1 Clock-period sweep

Keep utilization and placement density fixed:

| Variant | Period | Frequency |
|---|---:|---:|
| `logic_mock_10ns` | 10.0 ns | 100.0 MHz |
| `logic_mock_8ns` | 8.0 ns | 125.0 MHz |
| `logic_mock_7ns` | 7.0 ns | 142.9 MHz |
| `logic_mock_6ns` | 6.0 ns | 166.7 MHz |

For every run, compare:

- Setup and hold slack
- WNS/TNS
- Minimum period/Fmax
- Clock skew
- Buffer and inverter counts
- Area/utilization
- Power under identical activity assumptions
- Wirelength and congestion
- Antenna and DRC results

The recommended immediate next run is **8 ns**, because it meaningfully tightens the
constraint while retaining margin from the 5.80 ns reported minimum period.

---

## 12.2 Core-utilization sweep

After clock behavior is characterized:

```text
30% → 40% → 50% → 60%
```

Use a fixed clock period and placement density. Compare area, wirelength, congestion,
setup/hold timing and detailed-route completion.

---

## 12.3 Placement-density sweep

After selecting a reasonable utilization:

```text
0.45 → 0.55 → 0.65 → 0.75
```

Observe density heat maps, routing overflow, detailed-route violations and timing.

---

## 12.4 Power-activity refinement

Generate VCD or SAIF from a representative full inference and rerun power analysis.
This will enable meaningful comparisons of:

- Clock power
- MAC datapath power
- Controller power
- Sequential vs combinational activity
- Energy per inference

---

## 12.5 Memory-inclusive implementation

Replace mocked inferred memories with physically characterized macro views:

```text
.lib   timing and power
.lef   physical abstract
.gds   final macro geometry
.v     functional/black-box model
```

Only then should the project claim full DNN area, power, memory timing and final PPA.

---

# 13. Final status checklist

```text
[✓] RTL-to-Sky130HD synthesis
[✓] Floorplan and PDN
[✓] Standard-cell placement
[✓] Clock Tree Synthesis
[✓] Global routing
[✓] Detailed routing
[✓] SPEF RC extraction
[✓] Post-route setup timing closure
[✓] Post-route hold timing closure
[✓] Final routed ODB loaded in GUI
[✓] Antenna check: 0 net / 0 pin violations
[✓] Baseline area extracted
[✓] Baseline power extracted
[✓] Baseline wirelength extracted
[✓] Timing and logic-depth distributions extracted

[✓] Detailed-route DRC count confirmed from ORFS route metrics
[ ] Congestion heat map archived
[ ] Actual VCD/SAIF activity annotated
[ ] LEC restored or alternative equivalence completed
[ ] Multi-corner timing analysis
[ ] Clock-period sweep
[ ] Utilization sweep
[ ] Placement-density sweep
[ ] Real memory-macro integration
```

---

# 14. Portfolio-ready summary

> A previously bit-exact-verified MNIST DNN RTL design was implemented through a
> complete Sky130HD RTL-to-GDS flow using OpenROAD Flow Scripts. The first
> logic-only post-route baseline achieved setup and hold closure at 100 MHz, with
> +4.20 ns worst setup slack, +0.25 ns worst hold slack, a reported 5.80 ns minimum
> clock period, 67,417 µm² design area, 45% final utilization and 148.405 mm routed
> wirelength. The post-route critical path was identified in the Layer 3 signed MAC
> datapath, while the hold-critical path was a short Layer 2 state-register path.
> Large weight memories were explicitly separated as mocked structures, preventing
> the logic-only PPA from being misrepresented as a full memory-inclusive result.
