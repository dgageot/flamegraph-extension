import React from 'react';
import Button from '@mui/material/Button';
import { createDockerDesktopClient } from '@docker/extension-api-client';
import { Stack, TextField, Typography } from '@mui/material';
import { FlameGraph } from 'react-flame-graph';

// Note: This line relies on Docker Desktop's presence as a host application.
// If you're running this React app in a browser, it won't work properly.
const client = createDockerDesktopClient();

function useDockerDesktopClient() {
  return client;
}

function Flame(props) {
  const response = props.response;
  if (!response) {
    return <></>;
  }

  return <FlameGraph data={response} height={600} width={1000} />
}

export function App() {
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
  const ddClient = useDockerDesktopClient();

  const fetchAndDisplayResponse = async () => {
    setError(undefined);
    setResponse(undefined);
    setInProgress(true);

    ddClient.extension.vm?.service?.get(`/profileProcess?processName=${processName || ''}&duration=${duration || '5'}`)
      .then((profile) => { 
        setResponse(profile as string);
        setInProgress(false);
      })
      .catch((error)=> {
        setError(error.message.replace(/['"]+/g, ''));
        setInProgress(false);
      })
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
