MODULE ROS_motion_left

! Software License Agreement (BSD License)
!
! Copyright (c) 2012, Edward Venator, Case Western Reserve University
! Copyright (c) 2012, Jeremy Zoss, Southwest Research Institute
! All rights reserved.
!
! Redistribution and use in source and binary forms, with or without modification,
! are permitted provided that the following conditions are met:
!
!   Redistributions of source code must retain the above copyright notice, this
!       list of conditions and the following disclaimer.
!   Redistributions in binary form must reproduce the above copyright notice, this
!       list of conditions and the following disclaimer in the documentation
!       and/or other materials provided with the distribution.
!   Neither the name of the Case Western Reserve University nor the names of its contributors
!       may be used to endorse or promote products derived from this software without
!       specific prior written permission.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
! EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
! OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
! SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
! INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
! TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
! BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
! CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
! WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

! ----------------------------------------------
! ----------------- CONSTANTS ------------------
! ----------------------------------------------
LOCAL CONST zonedata DEFAULT_CORNER_DIST := z10;

! ----------------------------------------------
! ----------------- VARIABLES ------------------
! ----------------------------------------------
! Trajectory Variables
LOCAL VAR ROS_joint_trajectory_pt jointTrajectory{MAX_TRAJ_LENGTH};
LOCAL VAR num trajectory_size := 0;

! Flag Variables
LOCAL VAR bool hand_calibrated := FALSE;
LOCAL VAR bool program_started := FALSE;

! Task Name
LOCAL VAR string task_name := "M_Left";

! Syncronize Motion Variables
PERS tasks task_list{2} := [["T_ROB_R"],["T_ROB_L"]];
VAR syncident ready;
VAR syncident handCalibrated;

PROC main()
! MODIFIER: Frederick Wachter - wachterfreddy@gmail.com
! FIRST MODIFIED: 2016-06-14
! PURPOSE: Move the robot arm and gripper to specified trajectory
! NOTES: A gripper is attached to this arm (left arm)
! FUTURE WORK: Use the velociy values

    ! Initialize Variables
    VAR num current_index;
    VAR jointtarget target;
    VAR zonedata stop_mode;
    VAR bool skip_move;

    ! Syncronize Tasks
    IF (program_started = FALSE) THEN
        WaitSyncTask ready, task_list \TimeOut:=20;
        program_started := TRUE;
    ELSE
        TPWrite task_name + ": Program restarted.";
    ENDIF

    ! Make Sure YuMi Wont Start Running Previous Stored Trajectory
    ROS_new_trajectory_left := FALSE;
    trajectory_size := 0;
    ClearPath;

    ! Get Trajectory and Move Arm
    WHILE true DO
        ! Check For New Trajectory
        IF (ROS_new_trajectory_left)
            init_trajectory;

        ! Execute All Points in Trajectory
        IF (trajectory_size > 0) THEN
            TPWrite task_name + ": Running Trajectory";

            FOR current_index FROM 1 TO trajectory_size DO
                target.robax := jointTrajectory{current_index}.joint_pos.robax;
                target.extax.eax_a := jointTrajectory{current_index}.joint_pos.extax.eax_a;

                skip_move := (current_index = 1) AND is_near(target.robax, 0.1);

                ! If At Final Point, Make Fine Movement, Otherwise Use Zone Movements
                IF (current_index = trajectory_size) THEN
                    stop_mode := fine; ! stop at path end
                ELSE
                    stop_mode := DEFAULT_CORNER_DIST; ! assume we are smoothing between points
                ENDIF

                ! Execute move command
                IF (NOT skip_move) THEN
                    MoveAbsJ target, NORM_SPEED, \T:=jointTrajectory{current_index}.duration, stop_mode, tool0; ! move arm
                ENDIF
            ENDFOR

            trajectory_size := 0;  ! trajectory done
            TPWrite task_name + ": Finished Trajectory";
        ENDIF
        
        WaitTime 0.05;  ! throttle loop while waiting for new command
    ENDWHILE
ERROR (ERR_WAITSYNCTASK)
    IF (ERRNO=ERR_WAITSYNCTASK) THEN
        ErrWrite \W, "WaitSync timeout", "Waited too long for hand calibration";
        TPWrite "Wait sync error";
    ELSE
        ErrWrite \W, "Motion Error", "Error executing motion.  Aborting trajectory.";
        TPWrite("Error Number: " + ValToStr(ERRNO) + " | Error executing motion");
        abort_trajectory;
    ENDIF
ENDPROC

LOCAL PROC init_trajectory()
! MODIFIER: Frederick Wachter - wachterfreddy@gmail.com
! FIRST MODIFIED: 2016-06-14
! PURPOSE: Get joint trajectory
! NOTES: A gripper is not attached to this arm (left arm)

    clear_path; ! cancel any active motions

    ! Get Trajectory For Arm
    WaitTestAndSet ROS_trajectory_lock_left; ! acquire data-lock
    jointTrajectory := ROS_trajectory_left; ! copy joint trajectory to local variable
    trajectory_size := ROS_trajectory_size_left; ! get the trajectory size
    ROS_new_trajectory_left  := FALSE; ! set flag to indicate that the new trajectory has already been retrived
    ROS_trajectory_lock_left := FALSE; ! release data-lock
    
ENDPROC

LOCAL FUNC bool is_near(robjoint target, num tol)
    VAR jointtarget curr_jnt;
    
    curr_jnt := CJointT();
    
    RETURN ( ABS(curr_jnt.robax.rax_1 - target.rax_1) < tol )
       AND ( ABS(curr_jnt.robax.rax_2 - target.rax_2) < tol )
       AND ( ABS(curr_jnt.robax.rax_3 - target.rax_3) < tol )
       AND ( ABS(curr_jnt.robax.rax_4 - target.rax_4) < tol )
       AND ( ABS(curr_jnt.robax.rax_5 - target.rax_5) < tol )
       AND ( ABS(curr_jnt.robax.rax_6 - target.rax_6) < tol );
ENDFUNC

LOCAL PROC abort_trajectory()
    trajectory_size := 0;  ! "clear" local trajectory
    clear_path;
    ExitCycle;  ! restart program
ENDPROC

LOCAL PROC clear_path()
    IF ( NOT (IsStopMoveAct(\FromMoveTask) OR IsStopMoveAct(\FromNonMoveTask)) ) THEN
        StopMove; ! stop any active motions
    ENDIF
    ClearPath; ! clear queued motion commands
    StartMove; ! re-enable motions
ENDPROC

ENDMODULE


