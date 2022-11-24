import React from 'react';
import Button from '@mui/material/Button';
import { createDockerDesktopClient } from '@docker/extension-api-client';
import { Stack, TextField, Typography } from '@mui/material';
import { FlameGraph } from 'react-flame-graph';

const client = createDockerDesktopClient();
function useDockerDesktopClient() {
  return client;
}

export function App() {
  const ddClient = useDockerDesktopClient();
  const [response, setResponse] = React.useState<string>();
  const [processName, setProcessName] = React.useState<string>("");
  const [duration, setDuration] = React.useState<string>("5");
  const [error, setError] = React.useState<string>();
  const [inProgress, setInProgress] = React.useState<boolean>();

  const handleSetDuration = (event: React.ChangeEvent<HTMLInputElement>) => {
    setDuration(event.target.value);
  };
  const handleSetProcessName = (event: React.ChangeEvent<HTMLInputElement>) => {
    setProcessName(event.target.value);
  };

  const fetchAndDisplayResponse = async () => {
    setError(undefined);
    setResponse(undefined);
    setInProgress(true);
    try {
      let imageName: string;
      try {
        const response = await ddClient.extension.vm?.service?.get(`/imageName`);
        imageName = response as string;
      } catch (error) {
        setError(JSON.parse(error.message).message);
        return;
      }

      try {
        const response = await ddClient.docker.cli.exec("run", [
          "--rm",
          "--pid=host",
          "--privileged=true",
          "-v",
          "/lib/modules:/lib/modules",
          imageName,
          "/entrypoint.sh",
          processName == "" ? '\"\"' : processName,
          duration,
        ]);
        setResponse(JSON.parse(response.stdout));
      } catch (error) {
        setError(dockerCliError(error));
      }
    } finally {
      setInProgress(false);
    }
  };

  return (
    <>
      <Typography variant="h3">Flamegraph</Typography>

      <Stack spacing={2}>
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Choose a process name or ID and a duration. It will then profile this application and show a flamegraph.
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Tip: If no process name is provided, the process that currently consumes the most CPU will be profiled.
        </Typography>

        <Stack direction="row" spacing={2}>
          <TextField id="outlined-basic" label="Process Name or ID" value={processName} onChange={handleSetProcessName} variant="standard" disabled={inProgress} />
          <TextField id="outlined-basic" label="Duration (s)" value={duration} onChange={handleSetDuration} variant="standard" disabled={inProgress} />
          <Button variant="contained" onClick={fetchAndDisplayResponse} disabled={inProgress}>
            {inProgress ? "Profiling, please wait..." : "Profile"}
          </Button>
        </Stack>
        <Flame response={response} />
        <Typography variant="body1" color="red">{error}</Typography>
      </Stack>
    </>
  );
}

function Flame(props) {
  const response = props.response;
  if (!response) {
    return <></>;
  }

  return <FlameGraph data={response} height={600} width={1000} />
}

function dockerCliError(error) {
  switch (error.code) {
    case 130: return "process not provided";
    case 131: return "duration not provided";
    case 132: return "duration not provided";
    case 133: return "java applications should be started with -XX:+PreserveFramePointer";
    default: return error.stderr;
  }
}
