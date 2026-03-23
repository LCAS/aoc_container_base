# LCAS/aoc_container_base

A repository of verstile Docker containers, orginally developed as apart of the [Agri-OpenCore (AOC) project](https://agri-opencore.org) stack.

This repository provides us with the following containers:

| Container Name | Varients | Purpose | File |
| --- | --- | --- | --- |
| `lcas.lincoln.ac.uk/ros` | `humble` `jazzy` | Base ROS Container, the minimal environment you need for ROS | [base.dockerfile](base.dockerfile) |
| `lcas.lincoln.ac.uk/ros_cuda` | `humble` `jazzy` | ROS + Nvidia. When you need to use a GPU in your ROS environment for either better quality simulation or AI workloads. | [cuda.dockerfile](cuda.dockerfile) |
| `lcas.lincoln.ac.uk/ros_cuda_desktop` | `humble` `jazzy` | ROS + Nvidia + Packages. Installs the `ros-{distro}-desktop` varient so there is the full ROS stack available. | [cuda_desktop.dockerfile](cuda_desktop.dockerfile) |
| `lcas.lincoln.ac.uk/vnc` | `latest` | Standalone VNC container that can take X11 visualisations and show them in a browser. | [vnc.dockerfile](vnc.dockerfile) |
| `lcas.lincoln.ac.uk/vnc_devtools` | `latest` | Adds development tools such as a terminal for the standard VNC environment. | [vnc_devtools.dockerfile](vnc_devtools.dockerfile) |

These containers are built from three standard container images, `ros`, `nvidia/cuda` and `debian`. Each container is either built from one of these pre-existing images or one derrived from it in this pattern.

```mermaid
flowchart TB
    library/ros["library/ros"] --> lcas/ros["lcas/ros"]
    nvidia/cuda["nvidia/cuda"] --> lcas/ros_cuda["lcas/ros_cuda"]
    lcas/ros_cuda --> lcas/ros_cuda_desktop["lcas/ros_cuda_desktop"]
    debian["debian"] --> vnc["vnc"]
    vnc --> vnc_devtools["vnc_devtools"]

    style library/ros stroke-width:1px,stroke-dasharray: 1,fill:#ffffff
    style lcas/ros fill:#BBDEFB
    style nvidia/cuda stroke-width:1px,stroke-dasharray: 1,fill:#ffffff
    style lcas/ros_cuda fill:#BBDEFB
    style lcas/ros_cuda_desktop fill:#BBDEFB
    style debian stroke-width:1px,stroke-dasharray: 1,fill:#ffffff
    style vnc fill:#BBDEFB
    style vnc_devtools fill:#BBDEFB
```

## How can I use this?

This works best if you follow the [`ros2_workspace_template`](https://github.com/lcas/ros2_pkg_template), use this as a template to build your own repositories, that contain the packages you want to ship.

You can work either inside the devcontainer or by running the container yourself, and then when you are ready start by enabling the deployment workflows and adding automated testing. Then once you're happy move this onto a real robot platform - and keep iterating till it works!

```mermaid
%%{init: {"theme":"neutral","flowchart":{"curve":"linear"}}}%%
flowchart LR
  Dev["Develop in the Devcontainer"]
  Workflows["Activate Workflows to Build and Push Images"]
  AutoTest["Add Automated Testing Steps Where Possible"]
  Deploy["Add/Update Your Container on to the Platform Deployment Repository"]
  RealTest["Test the Packages on a Real Robot"]
  Outcome{"Did it work well?"}
  Fix(("Make changes that will fix the issues"))
  Complete(["✅  Complete"])

  %% main flow
  Dev --> Workflows --> AutoTest --> Deploy --> RealTest --> Outcome
  Outcome -- "Yes" --> Complete
  Outcome -- "No" --> Fix --> AutoTest

  %% iterative dev loop (renders as a real loop in GitHub)
  Dev -. "Iterate" .-> Iter(("🔄"))
  Iter -.-> Dev

  %% keep it subtle (GitHub-friendly)
  classDef loop fill:transparent,stroke:#999,stroke-width:1px;
  class Iter loop;
```

#
