$client = New-Object System.Net.Sockets.TcpClient
$client.ReceiveTimeout = 2000
$client.SendTimeout = 2000
try {
    $client.Connect("127.0.0.1", 9876)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $reader = New-Object System.IO.StreamReader($stream)
    $writer.AutoFlush = $true
    
    # Try sending JSON request
    $msg = '{"jsonrpc": "2.0", "method": "ping", "id": 1}'
    $writer.WriteLine($msg)
    
    $line = $reader.ReadLine()
    Write-Output "Response: $line"
} catch {
    Write-Output "Error: $($_.Exception.Message)"
} finally {
    $client.Close()
}
