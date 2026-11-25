
Module Database

    Private _connectionString As String

    Private Function LoadSettings() As Dictionary(Of String, String)
        Dim filePath As String = System.IO.Path.Combine(AppContext.BaseDirectory, "connections.local.config")

        If Not File.Exists(filePath) Then
            Throw New FileNotFoundException(
                "connections.local.config was not found. Copy connections.example.config to " &
                "connections.local.config and enter your own MySQL details.", filePath)
        End If

        Dim settings As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        For Each line As String In File.ReadAllLines(filePath)
            Dim text As String = line.Trim()
            If text = "" OrElse text.StartsWith("#") Then Continue For
            Dim pos As Integer = text.IndexOf("="c)
            If pos > 0 Then
                settings(text.Substring(0, pos).Trim()) = text.Substring(pos + 1).Trim()
            End If
        Next
        Return settings
    End Function

    Public Function GetConnectionString() As String
        If _connectionString Is Nothing Then
            Dim s As Dictionary(Of String, String) = LoadSettings()
            Dim builder As New MySqlConnectionStringBuilder()
            builder.Server = s("Server")
            builder.Port = CUInt(s("Port"))
            builder.Database = s("Database")
            builder.UserID = s("User")
            builder.Password = s("Password")
            _connectionString = builder.ConnectionString
        End If
        Return _connectionString
    End Function

    ''' <summary>Returns a NEW, unopened connection. Use inside a Using block.</summary>
    Public Function GetConnection() As MySqlConnection
        Return New MySqlConnection(GetConnectionString())
    End Function

    ''' <summary>Quick check used at startup and while testing.</summary>
    Public Function TestConnection(ByRef message As String) As Boolean
        Try
            Using conn As MySqlConnection = GetConnection()
                conn.Open()
            End Using
            message = "Connected to MySQL successfully."
            Return True
        Catch ex As Exception
            message = "Could not connect: " & ex.Message
            Return False
        End Try
    End Function

End Module
