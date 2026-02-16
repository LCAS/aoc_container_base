# aoc_container_base

A repository of verstile ROS-enabled Docker containers, orginally developed as apart of the [Agri-OpenCore (AOC) project](https://agri-opencore.org).

| Container Name                        | Tags                  | Purpose                                                                                                                           |
| ------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `lcas.lincoln.ac.uk/ros`              | { `humble`, `jazzy` } | Base ROS Container, the minimal environment you need for ROS                                                                      |
| `lcas.lincoln.ac.uk/ros_cuda`         | { `humble`, `jazzy` } | ROS + Nvidia. When you need to use a GPU in your ROS environment for either better quality simulation or AI workloads.            |
| `lcas.lincoln.ac.uk/ros_cuda_desktop` | { `humble`, `jazzy` } | ROS + Nvidia + Packages. Installs the `ros-{distro}-desktop` varient so there is the full ROS stack available.                    |