## Name

Origami - Extended

## Author

Sajith Amma

## Version

1.2.1 (Origami alone is 1.2 )

## Description

This library is an extended version of Origami with additional features for signing a PDF. Using this extended library, we can prepare a PDF document for signature and genereate the signable hash.

A third party application can sign the generated hash and the signed data in PKCS #7 format can be inserted back to the prepared PDF

All other Origami details can be found in "README" file, in the root directory

## Usage

### Prepare a PDF for signing 

```ruby

  require 'origami' 

  #load a sample PDF file

  mypdf = Origami::PDF.read "./sample.pdf"

  # location, contact, reason etc are optional parameters

  hash_to_be_signed = mypdf.prepare_for_sign (   
  
      :location => "Your Location", 
      :contact => "sample@email.com", 
      :reason => "Your Reason for signing here," 

  )

  ```

  An Optional parameter :signature_size can be passed, if the signature has different size (default it is: 1111)

  #send this hash_to_be_signed to a 3rd party application to sign (output must be in PKC#7 format )

  #save the PDF for inserting signature later
  mypdf.save('prepared.pdf')


### Insert a signed data inside the prepared PDF

```ruby

require 'origami'


mypdf = Origami::PDF.read "prepared.pdf"

# the pdf should be a prepared pdf using the prepare_for_sign method

# eg signature in PKCS #7 format

signature_base64 = 

"MIIEUwYJKoZIhvcNAQcCoIIERDCCBEACAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3DQEHAaCCArgwggK0MIICHaADAgECAggSmghu6WrtzjANBgkqhkiG9w0BAQUFADBSMR8wHQYDVQQDDBZNb2JpbGVFeHByZXNzU3RhZ2luZ0NBMSIwIAYDVQQKDBlNb2JpbGUgRXhwcmVzcyBTdGFnaW5nIENBMQswCQYDVQQGEwJJTjAeFw0xMjA5MDMxMzIzNDNaFw0xNDA5MDMxMzIzNDNaMGYxEzARBgNVBAMMClZhbGltb1Rlc3QxHTAbBgNVBAsMFDg5MTA2MDEyMDYxMzcxNTk4OTFGMQ8wDQYDVQQKDAZWYWxpbW8xEjAQBgoJkiaJk/IsZAEZFgJOUjELMAkGA1UEBhMCSU4wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJ64wMdgBbuTHhuD2UZvGazKmTDehVy03/yjwH5ZEb7VoLlOUG4RXBg2M8N0i9lqCiO+GI0aKpGP6Tfi9QtmXH8Fkt6VqeWSAVZXVHiMqZGFNAUcKG2JfAUdPTqBCB72nSdn0W6yqxAe4Vj80aux23hMsPVqieNmh0rTZhA2oITfAgMBAAGjfzB9MB0GA1UdDgQWBBQYIur/PPhTKfNKPm5hGf9uEUUgFzAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFKhsCBwF5B7wwqeErPH1/46KWJ5cMA4GA1UdDwEB/wQEAwIF4DAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwQwDQYJKoZIhvcNAQEFBQADgYEAJ8zHO0h99vuK+VntfCzfbfKy/6YiJmKkXiU6pFmVGgvTOTTodNTwAQoRx9csaJwOnawPM8IYU+O/ldjvCfD+wycj+AgEPq2Up9N8AbvIcw6dIjRg4b6JBFVYYl6vdnl4N353hQFjxsuDBl4yjHx/rNz7YuDOx4d5XSJwGOSQwX4xggFjMIIBXwIBATBeMFIxHzAdBgNVBAMMFk1vYmlsZUV4cHJlc3NTdGFnaW5nQ0ExIjAgBgNVBAoMGU1vYmlsZSBFeHByZXNzIFN0YWdpbmcgQ0ExCzAJBgNVBAYTAklOAggSmghu6WrtzjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTIxMDExMTEzNzI5WjAjBgkqhkiG9w0BCQQxFgQUjHEpwYp6rT/FIVWAbbq9lq3/79IwDQYJKoZIhvcNAQEBBQAEgYAoHgDdmt1TrtZ3k8ODQyKOtHAJgYCg1/kdqocREPhz/1U2w+OUOrwhb7u/lh0F+6jhMevzg0RNG7vkJIS1jTS15Kxlv2teW2/VdGSsdF5wmqY837fB6G3IhSuUEAtSZfG7JEAoxg36TTPgeaUxpZf0ER2jRsud9dD5hm14j+5GLw=="


# insert the signature inside the PDF

mypdf.insert_sign( signature_base64)

# Save the signed PDF

mypdf.save('sign-attached.pdf')

```


