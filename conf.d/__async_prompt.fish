status is-interactive
or exit 0

set -g __async_prompt_var _async_prompt_$fish_pid

not set -q async_prompt_repaint_delay
and set async_prompt_repaint_delay 0.000000001

# Setup after the user defined prompt functions are loaded.
function __async_prompt_setup_on_startup --on-event fish_prompt
    functions -e (status current-function)
    if test "$async_prompt_enable" = 0
        return 0
    end

    for func in (__async_prompt_config_functions)
        set -U $__async_prompt_var'_'$func
        function $func -V func
            if set -q $__async_prompt_var'_'$func
                set -l result $__async_prompt_var'_'$func
                printf "%s\n" $$result
            end
        end
    end
end

set -g __async_prompt_last_pipestatus 0
function __async_prompt_keep_last_pipestatus --on-event fish_postexec
    set -g __async_prompt_last_pipestatus $pipestatus
end

not set -q async_prompt_on_variable
and set async_prompt_on_variable fish_bind_mode
function __async_prompt_fire --on-event fish_prompt (for var in $async_prompt_on_variable; printf '%s\n' --on-variable $var; end)
    __async_prompt_keep_last_pipestatus

    for func in (__async_prompt_config_functions)
        if functions -q $func'_loading_indicator' && set -q $__async_prompt_var'_'$func
            set -l last_prompt $__async_prompt_var'_'$func
            set $__async_prompt_var'_'$func ($func'_loading_indicator' $$last_prompt)
        end

        __async_prompt_config_inherit_variables | __async_prompt_spawn \
            $func
    end
end

function __async_prompt_spawn -a cmd
    set -l envs
    begin
        while read line
            switch "$line"
                case fish_bind_mode
                    echo fish_bind_mode $fish_bind_mode
                case FISH_VERSION PWD _ history 'fish_*' hostname version status_generation
                case status pipestatus
                    echo pipestatus $__async_prompt_last_pipestatus
                case SHLVL
                    set envs $envs SHLVL=$SHLVL
                case '*'
                    echo $line (string escape -- $$line)
            end
        end
    end | read -lz vars
    echo $vars | env $envs fish -c '
    function __async_prompt_signal
        kill -s "'(__async_prompt_config_internal_signal)'" '$fish_pid' 2>/dev/null
    end
    while read -a line
        test -z "$line"
        and continue

        if test "$line[1]" = pipestatus
            set -f _pipestatus $line[2..]
        else
            eval set "$line"
        end
    end

    function __async_prompt_set_status
        return $argv
    end
    if set -q _pipestatus
        switch (count $_pipestatus)
            case 1
                __async_prompt_set_status $_pipestatus[1]
            case 2
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2]
            case 3
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3]
            case 4
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4]
            case 5
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4] \
                | __async_prompt_set_status $_pipestatus[5]
            case 6
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4] \
                | __async_prompt_set_status $_pipestatus[5] \
                | __async_prompt_set_status $_pipestatus[6]
            case 7
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4] \
                | __async_prompt_set_status $_pipestatus[5] \
                | __async_prompt_set_status $_pipestatus[6] \
                | __async_prompt_set_status $_pipestatus[7]
            case 8
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4] \
                | __async_prompt_set_status $_pipestatus[5] \
                | __async_prompt_set_status $_pipestatus[6] \
                | __async_prompt_set_status $_pipestatus[7] \
                | __async_prompt_set_status $_pipestatus[8]
            default
                __async_prompt_set_status $_pipestatus[1] \
                | __async_prompt_set_status $_pipestatus[2] \
                | __async_prompt_set_status $_pipestatus[3] \
                | __async_prompt_set_status $_pipestatus[4] \
                | __async_prompt_set_status $_pipestatus[5] \
                | __async_prompt_set_status $_pipestatus[6] \
                | __async_prompt_set_status $_pipestatus[7] \
                | __async_prompt_set_status $_pipestatus[8] \
                | __async_prompt_set_status $_pipestatus[-1]
        end
    else
        true
    end
    set '$__async_prompt_var\'_\'$cmd' ('$cmd')
    __async_prompt_signal' &
    if test (__async_prompt_config_disown) = 1
        builtin disown
    end
end

function __async_prompt_config_inherit_variables
    if set -q async_prompt_inherit_variables
        if test "$async_prompt_inherit_variables" = all
            set -ng
        else
            for item in $async_prompt_inherit_variables
                echo $item
            end
        end
    else
        echo CMD_DURATION
        echo fish_bind_mode
        echo pipestatus
        echo SHLVL
        echo status
    end
    echo __async_prompt_last_pipestatus
end

function __async_prompt_config_functions
    set -l funcs (
        if set -q async_prompt_functions
            string join \n $async_prompt_functions
        else
            echo fish_prompt
            echo fish_right_prompt
        end
    )
    for func in $funcs
        functions -q "$func"
        or continue

        echo $func
    end
end

function __async_prompt_config_internal_signal
    if test -z "$async_prompt_signal_number"
        echo SIGUSR1
    else
        echo "$async_prompt_signal_number"
    end
end

function __async_prompt_config_disown
    if test -z "$async_prompt_disown"
        echo 1
    else
        echo "$async_prompt_disown"
    end
end

function __async_prompt_repaint_prompt --on-signal (__async_prompt_config_internal_signal)
    if test $async_prompt_repaint_delay -gt 0
        sleep $async_prompt_repaint_delay
    end
    commandline -f repaint >/dev/null 2>/dev/null
end

function __async_prompt_variable_cleanup --on-event fish_exit
    set -l prefix (string replace $fish_pid '' $__async_prompt_var)
    set -l prompt_vars (set --show | string match -rg '^\$('"$prefix"'\d+_[a-z_]+):' | uniq)
    for var in $prompt_vars
        set -l pid (string match -rg '^'"$prefix"'(\d+)_[a-z_]+' $var)
        if not ps $pid &> /dev/null
            or test $pid -eq $fish_pid
            set -Ue $var
        end
    end
    set -ge __async_prompt_var
end
