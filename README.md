# MNIST DNN ASIC Physical Design

> **Status: First Sky130HD logic-only RTL-to-GDS baseline completed**
>
> 기존 `MNIST_DNN_RTL` 프로젝트에서 기능 검증한 MNIST DNN RTL을
> 구조적으로 변경하지 않고, OpenROAD Flow Scripts(ORFS)와 Sky130HD
> 표준셀을 이용해 합성, floorplan, placement, CTS, routing, RC
> extraction, post-route timing/power report까지 수행한 Physical Design
> 프로젝트입니다.

최종 업데이트 기준: 2026-07-14

---

## 1. 프로젝트 목표

이 프로젝트의 목적은 새로운 신경망 구조를 만드는 것이 아닙니다.

기존 Python 정수 모델과 bit-exact 검증을 완료한 RTL을 고정한 상태에서,
소프트웨어 EDA 툴로 실제 디지털 칩 구현 흐름을 수행하고 다음을
분석합니다.

```text
검증된 Verilog RTL
    ↓
Sky130HD 표준셀 합성
    ↓
Floorplan 및 전원망
    ↓
Standard-cell placement
    ↓
Clock Tree Synthesis
    ↓
Global / detailed routing
    ↓
RC parasitic extraction
    ↓
Post-route Static Timing Analysis
    ↓
Area / timing / power / congestion 분석
    ↓
동일 RTL에서 물리 설계 파라미터 sweep
```

1차 목표에서는 다음 RTL 구조를 변경하지 않습니다.

- Dense engine 구조
- Layer 1 / 2 / 3 구조
- MAC 개수
- 데이터 비트 폭
- Requantization
- Argmax
- 전체 controller

변경하는 것은 clock constraint, core utilization, placement density,
aspect ratio 등 **물리 구현 조건**입니다.

---

## 2. 기존 RTL 프로젝트와의 관계

원본 RTL은 submodule로 고정되어 있습니다.

```text
third_party/MNIST_DNN_RTL
```

사용 중인 RTL commit:

```text
docs/RTL_SOURCE_COMMIT.txt
```

현재 고정 commit:

```text
d5315d5f4d558a350e32b6cd807fd07072fa6e8f
```

기존 RTL 프로젝트에서 완료한 작업:

```text
PyTorch Float32 DNN 학습
→ 8-bit 정수 양자화
→ Python 정수 Golden Model
→ Verilog RTL 구현
→ Layer 1 / Layer 2 / Layer 3 검증
→ Streaming signed Argmax
→ Full DNN Controller
→ 16개 이미지 bit-exact regression
→ Generic Yosys synthesis
```

이 프로젝트는 그 다음 단계인 **공정 표준셀 기반 Physical
Implementation**을 담당합니다.

---

## 3. 현재 완료 상태

```text
[x] Docker Engine 설치 및 EDA 파티션 저장 설정
[x] OpenROAD Flow Scripts Docker 환경 구축
[x] Sky130HD GCD 공식 예제 RTL-to-GDS 완료
[x] OpenROAD GUI 실행 확인
[x] 기존 DNN RTL submodule 연결
[x] 10 ns SDC 및 ORFS config 작성
[x] 대형 weight ROM의 표준셀 직접 합성 한계 확인
[x] Logic-mock 표준셀 합성 완료
[x] Logic-mock floorplan 완료
[x] Logic-mock placement 완료
[x] Logic-mock CTS 완료
[x] Logic-mock global routing 완료
[x] Logic-mock detailed routing 완료
[x] Logic-mock RC extraction 및 final 단계 완료
[x] `6_final.odb` / `6_final.def` / `6_final.gds` 생성 확인
[x] Baseline timing / area / power / routing metric 1차 정리

[ ] GUI heat map 기반 congestion 위치 분석
[ ] Critical path layout 위치 분석
[ ] Clock tree 및 skew 상세 분석
[ ] Report 기반 DRC/antenna 결과 최종 정리
[ ] Clock-period sweep
[ ] Core-utilization sweep
[ ] Placement-density sweep
[ ] 최적 물리 구현 조건 선정
[ ] Memory-inclusive 구현 전략 검토
```

---

## 4. 현재 Baseline 설정

| 항목 | 설정 |
|---|---|
| Platform | Sky130HD |
| Top module | `mnist_dnn_pd_top` |
| Design nickname | `mnist_dnn_pd` |
| Flow variant | `logic_mock_10ns` |
| Clock period | 10 ns |
| Nominal target | 100 MHz |
| Core utilization target | 40% |
| Core aspect ratio | 1.0 |
| Core margin | 10 |
| Placement density | 0.55 |
| LEC | 비활성화 (`LEC_CHECK=0`) |
| Large inferred memory | Mock 처리 |
| ORFS execution | Docker wrapper |

관련 파일:

```text
config/sky130hd/config.mk
constraints/mnist_dnn_core_10ns.sdc
pd/mnist_dnn_pd_top.v
scripts/orfs.sh
scripts/check_inputs.sh
```

`mnist_dnn_pd_top`은 RTL 구조를 바꾸지 않고, ORFS Docker 내부에서
보이는 weight/bias `.mem` 경로를 연결하고 verification-only debug
port를 top-level physical-design interface에서 제외하는 wrapper입니다.

---

## 5. Baseline 결과 요약

현재 local run에는 다음 final 산출물이 생성되어 있습니다.

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.odb
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.def
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.gds
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.v
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.sdc
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.spef
```

대표 metric:

| 항목 | `logic_mock_10ns` 결과 |
|---|---:|
| Setup WNS | 0.00 ns |
| Setup TNS | 0.00 ns |
| Worst setup slack | 4.20 ns |
| Setup violation count | 0 |
| Hold TNS | 0.00 ns |
| Worst hold slack | 0.247 ns |
| Hold violation count | 0 |
| Minimum clock period | 5.80 ns |
| Estimated Fmax | 172.30 MHz |
| Setup clock skew | 0.142 ns |
| Hold clock skew | 0.137 ns |
| Die area | 166,607 um^2 |
| Core area | 149,776 um^2 |
| Standard-cell area | 67,417.2 um^2 |
| Final utilization | 45.01% |
| Total instances including fill/tap | 20,328 |
| Standard-cell instances | 6,947 |
| Macro count | 0 |
| Detailed-route wirelength | 148,450 um |
| Detailed-route via count | 38,795 |
| Detailed-route DRC errors | 0 |
| Antenna violating nets / pins | 0 / 0 |
| Total power | 10.717 mW |

Power breakdown:

| Group | Internal | Switching | Leakage | Total | Ratio |
|---|---:|---:|---:|---:|---:|
| Sequential | 5.14 mW | 0.0597 mW | ~0 mW | 5.20 mW | 48.5% |
| Combinational | 0.311 mW | 0.386 mW | ~0 mW | 0.697 mW | 6.5% |
| Clock | 2.78 mW | 2.04 mW | ~0 mW | 4.82 mW | 45.0% |
| Macro | 0 mW | 0 mW | 0 mW | 0 mW | 0.0% |
| Total | 8.23 mW | 2.49 mW | ~0 mW | 10.717 mW | 100% |

주의할 점:

- 현재 power는 실제 MNIST switching activity를 완전히 반영한 값이
  아니라 vectorless/default activity 기반 추정으로 보아야 합니다.
- `Macro`가 0인 이유는 현재 baseline이 memory-inclusive 결과가 아니라
  logic-mock 결과이기 때문입니다.
- 따라서 이 결과는 compute/control logic 중심의 첫 physical-design
  baseline으로 해석해야 합니다.

---

## 6. 지금까지 수행한 RTL-to-GDS 과정

### 6.1 Synthesis

입력 RTL을 Sky130HD 표준셀 netlist로 변환했습니다.

```text
RTL의 always / case / if / add / multiply
→ MUX / NAND / NOR / DFF / buffer / 표준셀 조합
```

주요 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/1_2_yosys.v
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/1_synth.odb
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/synth_stat.txt
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/synth_mocked_memories.txt
```

합성 결과의 핵심:

- Synthesized cell count: 4,847
- Synthesized chip area: 60,272.8064 um^2
- Sequential element area ratio: 54.20%
- Mocked memory report에 `8 x 2048`, `8 x 50176` inferred memory가 기록됨

### 6.2 Floorplan

Die/core 영역과 standard-cell row를 정의했습니다.

수행 항목:

- Die/Core 크기 결정
- Aspect ratio 적용
- Core utilization 반영
- I/O pin 배치
- Tap cell / well tie 삽입
- Power Distribution Network 생성

주요 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/2_floorplan.odb
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/2_floorplan_final.rpt
```

### 6.3 Placement

합성된 standard cell에 실제 좌표를 부여했습니다.

```text
Global placement
→ Timing / congestion 기반 최적화
→ Cell resize / buffer insertion / pin swap / cloning
→ Detailed placement
→ Legalization
```

주요 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/3_place.odb
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/3_global_place.rpt
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/3_detailed_place.rpt
```

### 6.4 Clock Tree Synthesis

Clock을 모든 sequential cell에 전달하기 위한 clock tree를 만들었습니다.

```text
Clock input
→ Clock buffer branches
→ DFF clock pins
```

주요 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/4_cts.odb
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/4_cts_final.rpt
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/cts_default_core_clock.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/cts_default_core_clock_layout.webp
```

### 6.5 Global Routing

모든 net의 대략적인 배선 경로와 사용할 금속층을 결정했습니다.

주요 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/5_1_grt.odb
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/route.guide
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/5_global_route.rpt
```

Global route 결과:

- Wirelength: 236,435 um
- Via count: 39,737
- Setup/Hold violation count: 0 / 0
- Antenna violating nets/pins: 0 / 0

### 6.6 Detailed Routing

Global routing guide를 기반으로 실제 metal segment와 via 좌표를
결정했습니다.

```text
Pin
→ Metal segment
→ Via
→ Higher metal
→ Destination pin
```

Detailed route 결과:

- 최종 DRC errors: 0
- Wirelength: 148,450 um
- Via count: 38,795
- Antenna violating nets/pins: 0 / 0

### 6.7 RC Extraction 및 Final Analysis

실제 배선에서 발생하는 저항과 커패시턴스를 추출하고, 이를 이용해
post-route timing을 계산했습니다.

```text
Total path delay
=
Standard-cell delay
+
Extracted wire RC delay
```

최종 산출물:

```text
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.odb
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.def
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.gds
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.v
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.sdc
results/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_final.spef
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_finish.rpt
logs/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_report.json
```

---

## 7. 중요한 제한: `logic_mock_10ns`

현재 결과는 **완전한 memory-inclusive DNN PPA 결과가 아닙니다.**

원본 RTL의 가장 큰 weight ROM:

```text
Layer 1 Weight ROM
= 50,176 rows x 8 bits
= 401,408 bits
```

이를 standard cell의 DFF와 MUX로 직접 펼치면 합성 시간과 면적이
비현실적으로 증가합니다. 따라서 현재 baseline은 다음 설정을 사용합니다.

```makefile
SYNTH_MEMORY_MAX_BITS = 4096
SYNTH_MOCK_LARGE_MEMORIES = 1
```

현재 결과로 유효하게 분석할 수 있는 것:

- Dense engine compute logic
- MAC datapath
- Controller
- Requantization
- Argmax
- Clock distribution
- Standard-cell placement
- Logic routing
- Compute/control 중심 timing
- Logic-only area 및 congestion 경향
- 물리 설계 파라미터 간 상대 비교

현재 결과로 최종 주장하면 안 되는 것:

- 실제 전체 weight ROM 면적
- 실제 전체 memory power
- SRAM 접근 지연을 포함한 최종 timing
- Memory-inclusive 최종 칩 면적
- 실제 전체 DNN의 최종 PPA

향후 별도 단계에서 memory macro를 연결해야 완전한 memory-inclusive
분석이 가능합니다.

---

## 8. 중요한 제한: LEC 비활성화

호스트 CPU와 현재 ORFS Docker image의 LEC 실행 바이너리 사이에서
`illegal instruction`이 발생하여 다음 설정을 사용했습니다.

```makefile
LEC_CHECK = 0
```

따라서 이번 ORFS 실행에서 resizer 전후 Logic Equivalence Check는
수행되지 않았습니다.

현재 기능 신뢰 근거:

- 원본 RTL의 cocotb bit-exact verification
- 16-vector full DNN regression
- ORFS flow의 정상 완료
- 최종 routed database 생성
- Post-route STA에서 setup/hold violation 0

추후 보완 항목:

- 호환 가능한 ORFS build에서 LEC 재실행
- Yosys equivalence flow 별도 구성
- Gate-level simulation
- 필요 시 SDF timing simulation

---

## 9. GUI에서 분석할 항목

Final GUI 실행:

```bash
./scripts/orfs.sh \
  FLOW_VARIANT=logic_mock_10ns \
  gui_final
```

현재 report에는 ORFS가 생성한 GUI snapshot도 있습니다.

```text
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_all.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_placement.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_routing.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_congestion.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_worst_path.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_clocks.webp
reports/sky130hd/mnist_dnn_pd/logic_mock_10ns/final_ir_drop.webp
```

GUI에서 확인할 항목:

- `Display Control -> Layers`: `met1`~`met5`, via 계층을 선택적으로 확인
- `Display Control -> Instances`: standard-cell 분포와 빈 영역 확인
- `Heat Maps -> Placement Density`: 고밀도 hotspot 확인
- `Heat Maps -> Routing Congestion`: routing overflow/hotspot 확인
- `Heat Maps -> Power Density`: clock/datapath power hotspot 확인
- `Timing -> Options`: worst setup/hold path를 layout에서 강조 확인
- `Windows -> Clock Tree Viewer`: clock tree depth, sink, branch balance 확인
- `Windows -> DRC Viewer`: DRC report가 있을 경우 violation 위치 확인

모든 layer를 동시에 켜면 화면이 복잡하므로, 한 번에 1~2개 metal
layer만 켜서 관찰하는 것이 좋습니다.

---

## 10. GUI Tcl Console에서 확인할 명령

OpenROAD GUI 아래 `TCL Commands` 창에서 실행합니다.

### 10.1 면적

```tcl
report_design_area
```

### 10.2 Setup timing

```tcl
report_wns
report_tns
report_worst_slack
report_clock_min_period -include_port_paths
```

상세 worst setup path:

```tcl
report_checks \
  -path_delay max \
  -fields {slew cap input net fanout} \
  -format full_clock_expanded
```

### 10.3 Hold timing

```tcl
report_checks \
  -path_delay min \
  -fields {slew cap input net fanout} \
  -format full_clock_expanded
```

### 10.4 Clock skew

```tcl
report_clock_skew
```

### 10.5 Power

```tcl
report_power
```

Power report에서는 다음을 구분합니다.

```text
Internal power
Switching power
Leakage power
Total power

Sequential
Combinational
Clock
Macro
Pad
```

현재 macro가 mock 처리되었기 때문에 `Macro power`는 실제 DNN weight
memory power를 의미하지 않습니다.

---

## 11. 터미널에서 Report 찾기

프로젝트 루트:

```bash
cd /media/joo/eda-data/MNIST_DNN_ASIC_PD
```

환경 변수:

```bash
VARIANT=logic_mock_10ns
REPORT_DIR="reports/sky130hd/mnist_dnn_pd/$VARIANT"
LOG_DIR="logs/sky130hd/mnist_dnn_pd/$VARIANT"
RESULT_DIR="results/sky130hd/mnist_dnn_pd/$VARIANT"
```

전체 report:

```bash
find "$REPORT_DIR" \
  -type f \
  -printf '%f\n' \
  | sort -V
```

Final result:

```bash
find "$RESULT_DIR" \
  -maxdepth 1 \
  -type f \
  -name "6_*" \
  -printf '%f  %k KB\n' \
  | sort -V
```

Timing 관련 report:

```bash
find "$REPORT_DIR" \
  -type f \
  \( \
    -iname "*timing*" \
    -o -iname "*finish*" \
    -o -iname "*route*" \
    -o -iname "*metrics*" \
  \) \
  -print
```

핵심 metric 검색:

```bash
grep -RniE \
  "report_tns|report_wns|report_worst_slack|report_clock_min_period|critical path|setup violation count|hold violation count|report_clock_skew|report_power|Design area" \
  "$REPORT_DIR" \
  2>/dev/null \
  | tail -300 \
  || true
```

Routing 및 DRC:

```bash
grep -RniE \
  "congestion|overflow|wirelength|via|Number of violations|DRC|antenna" \
  "$REPORT_DIR" \
  "$LOG_DIR" \
  2>/dev/null \
  | tail -300 \
  || true
```

---

## 12. 분석 시 가장 중요한 질문

### 기능 및 flow 완주

1. `6_final.odb`, `6_final.def`, `6_final.gds`가 모두 생성됐는가?
2. Flow 종료 코드가 0이었는가?
3. Final report가 생성됐는가?
4. `logs/sky130hd/mnist_dnn_pd/logic_mock_10ns/6_report.json`의
   `finish__flow__errors__count`가 0인가?

### Timing

1. 10 ns에서 setup WNS/TNS가 통과하는가?
2. Hold violation은 없는가?
3. Critical path는 MAC datapath인가, controller인가, I/O인가?
4. Path delay에서 cell delay와 wire delay 중 어느 쪽이 더 큰가?
5. 배치/배선 후 timing이 어느 단계에서 가장 악화됐는가?

### Area

1. Core utilization 40%가 final stage에서도 적절한가?
2. Final utilization 45.01%가 congestion과 timing에 어떤 영향을 주는가?
3. 빈 공간이 너무 많은가?
4. Buffer / inverter / clock buffer가 전체 cell에서 큰 비율을 차지하는가?
5. Fill/tap cell 포함 instance count와 실제 standard-cell count를 구분했는가?

### Congestion

1. Routing congestion hotspot은 어디인가?
2. Hotspot이 dense engine 주변인가, I/O 주변인가?
3. Placement density를 낮추면 해결될 가능성이 있는가?
4. Congestion 때문에 배선 우회와 timing 악화가 발생했는가?

### Power

1. Total power에서 sequential, combinational, clock 중 어느 항목이 큰가?
2. Clock network power 비중 45.0%를 줄일 여지가 있는가?
3. 고밀도/고배선 영역과 power hotspot이 일치하는가?
4. Vectorless/default activity 기반 power라는 한계를 어떻게 기록할 것인가?

---

## 13. 다음 실험: RTL을 바꾸지 않는 Sweep

모든 실험은 **한 번에 변수 하나만 변경**합니다.

### 13.1 Clock Period Sweep

예:

```text
clock_20ns
clock_12ns
clock_10ns
clock_8ns
clock_6ns
```

비교:

- Setup WNS / TNS
- Hold WNS / TNS
- Fmax
- Buffer / resized cell 수
- Area
- Power
- Routing congestion
- DRC

목적:

> 현재 RTL 구조가 물리적으로 timing closure를 달성할 수 있는 최소
> clock period를 찾는다.

### 13.2 Core Utilization Sweep

예:

```text
util_30
util_40
util_50
util_60
```

비교:

- Core area
- Wirelength
- Congestion
- Timing
- Power
- Routing 성공 여부

예상 경향:

```text
낮은 utilization
→ 큰 Core
→ 배선이 길어질 수 있음
→ 면적 증가

높은 utilization
→ 작은 Core
→ Cell 밀집
→ Congestion 및 DRC 위험 증가
```

### 13.3 Placement Density Sweep

예:

```text
density_045
density_055
density_065
density_075
```

비교:

- Placement density heat map
- Global routing overflow
- Detailed routing violation
- Wirelength
- Setup timing
- Buffer 수

### 13.4 Aspect Ratio Sweep

예:

```text
aspect_080
aspect_100
aspect_125
```

비교:

- 가로/세로 routing balance
- I/O pin distance
- Clock tree
- Congestion
- Critical path wire delay

---

## 14. 최종 비교표

| Variant | Period | Util. | Density | Setup WNS | Hold WNS | Area | Power | Wirelength | DRC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `logic_mock_10ns` | 10 ns | 40% target / 45.01% final | 0.55 | 0.00 ns | 0.247 ns slack | 67,417.2 um^2 stdcell | 10.717 mW | 148,450 um | 0 |
| `clock_8ns` | 8 ns | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| `util_50` | 10 ns | 50% | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| `density_065` | 10 ns | TBD | 0.65 | TBD | TBD | TBD | TBD | TBD | TBD |

최적 조건은 단순히 가장 빠른 결과가 아닙니다.

```text
Timing 통과
+
DRC clean
+
낮은 congestion
+
합리적인 area
+
낮은 power
```

를 동시에 고려해 선정합니다.

---

## 15. 재실행 방법

입력 확인:

```bash
./scripts/check_inputs.sh
```

Logic-mock synthesis:

```bash
./scripts/orfs.sh \
  FLOW_VARIANT=logic_mock_10ns \
  synth
```

Logic-mock full flow:

```bash
./scripts/orfs.sh \
  FLOW_VARIANT=logic_mock_10ns
```

Final GUI:

```bash
./scripts/orfs.sh \
  FLOW_VARIANT=logic_mock_10ns \
  gui_final
```

최종 결과 확인:

```bash
find results/sky130hd/mnist_dnn_pd/logic_mock_10ns \
  -maxdepth 1 \
  -type f \
  \( \
    -name "6_final.odb" \
    -o -name "6_final.def" \
    -o -name "6_final.gds" \
    -o -name "6_final.v" \
  \) \
  -printf "%f  %k KB\n" \
  | sort
```

---

## 16. 프로젝트 폴더 구조

```text
MNIST_DNN_ASIC_PD/
├── config/
│   └── sky130hd/
│       └── config.mk
├── constraints/
│   └── mnist_dnn_core_10ns.sdc
├── pd/
│   └── mnist_dnn_pd_top.v
├── scripts/
│   ├── orfs.sh
│   └── check_inputs.sh
├── third_party/
│   └── MNIST_DNN_RTL/
├── docs/
│   └── RTL_SOURCE_COMMIT.txt
├── artifacts/
│   └── logs/
├── logs/       # ORFS generated, Git 제외
├── objects/    # ORFS generated, Git 제외
├── reports/    # ORFS generated, Git 제외
├── results/    # ORFS generated, Git 제외
├── .gitignore
└── README.md
```

---

## 17. 1차 목표 완료 기준

```text
[x] Sky130HD technology mapping
[x] Floorplan
[x] Standard-cell placement
[x] Clock Tree Synthesis
[x] Global routing
[x] Detailed routing
[x] RC extraction
[x] Final routed ODB / DEF / GDS 생성
[x] Post-route setup/hold report 생성
[x] Logic-only baseline metric 정리

[ ] GUI 기반 placement/congestion/power hotspot 분석
[ ] Critical path 분석
[ ] Sweep 실험
[ ] Memory-inclusive 구현 계획 수립
```

---

## 18. 포트폴리오 표현

현재 단계의 정확한 표현:

> 기존 MNIST DNN RTL의 구조를 변경하지 않고 Sky130HD 표준셀 기반으로
> 합성, floorplan, placement, CTS, routing 및 RC extraction을 수행하여
> 최종 routed layout을 생성했다. 대형 inferred weight ROM은 표준셀 직접
> 합성의 비현실성을 확인한 뒤 logic-mock으로 분리하여 compute/control
> logic의 첫 Physical Design baseline을 확보했다.

전체 분석 완료 후 목표 표현:

> Clock period, core utilization, placement density를 변화시키며
> setup/hold timing, area, power, clock skew, wirelength 및 routing
> congestion의 trade-off를 비교하고, 동일 RTL에서 가장 균형 잡힌
> Physical Design 조건을 선정했다.

---

## 19. 향후 Memory-inclusive 단계

Logic-only 분석 후에는 원본 RTL 구조를 유지하면서 inferred memory를
실제 memory macro view에 연결합니다.

필요한 view:

```text
Liberty (.lib)  : timing / power
LEF             : physical abstract
GDS             : final layout
Verilog model   : functional / black-box model
```

이 단계가 완료되면 다음을 분석할 수 있습니다.

- Weight memory 포함 전체 면적
- Memory access timing
- Macro placement
- Macro 주변 routing congestion
- Memory 포함 전체 power
- Memory-inclusive final PPA

현재 `logic_mock_10ns`는 이 후속 작업을 위한 compute/control baseline입니다.
