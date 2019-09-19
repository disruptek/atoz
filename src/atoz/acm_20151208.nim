
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Certificate Manager
## version: 2015-12-08
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Certificate Manager</fullname> <p>Welcome to the AWS Certificate Manager (ACM) API documentation.</p> <p>You can use ACM to manage SSL/TLS certificates for your AWS-based websites and applications. For general information about using ACM, see the <a href="https://docs.aws.amazon.com/acm/latest/userguide/"> <i>AWS Certificate Manager User Guide</i> </a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/acm/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "acm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "acm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "acm.us-west-2.amazonaws.com",
                           "eu-west-2": "acm.eu-west-2.amazonaws.com", "ap-northeast-3": "acm.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "acm.eu-central-1.amazonaws.com",
                           "us-east-2": "acm.us-east-2.amazonaws.com",
                           "us-east-1": "acm.us-east-1.amazonaws.com", "cn-northwest-1": "acm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "acm.ap-south-1.amazonaws.com",
                           "eu-north-1": "acm.eu-north-1.amazonaws.com", "ap-northeast-2": "acm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "acm.us-west-1.amazonaws.com",
                           "us-gov-east-1": "acm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "acm.eu-west-3.amazonaws.com",
                           "cn-north-1": "acm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "acm.sa-east-1.amazonaws.com",
                           "eu-west-1": "acm.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "acm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "acm.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "acm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "acm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "acm.ap-southeast-1.amazonaws.com",
      "us-west-2": "acm.us-west-2.amazonaws.com",
      "eu-west-2": "acm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "acm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "acm.eu-central-1.amazonaws.com",
      "us-east-2": "acm.us-east-2.amazonaws.com",
      "us-east-1": "acm.us-east-1.amazonaws.com",
      "cn-northwest-1": "acm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "acm.ap-south-1.amazonaws.com",
      "eu-north-1": "acm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "acm.ap-northeast-2.amazonaws.com",
      "us-west-1": "acm.us-west-1.amazonaws.com",
      "us-gov-east-1": "acm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "acm.eu-west-3.amazonaws.com",
      "cn-north-1": "acm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "acm.sa-east-1.amazonaws.com",
      "eu-west-1": "acm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "acm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "acm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "acm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "acm"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToCertificate_772933 = ref object of OpenApiRestCall_772597
proc url_AddTagsToCertificate_772935(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToCertificate_772934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to an ACM certificate. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a <code>key</code> and an optional <code>value</code>. You specify the certificate on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. </p> <p>You can apply a tag to just one certificate if you want to identify a specific characteristic of that certificate, or you can apply the same tag to multiple certificates if you want to filter for a common relationship among those certificates. Similarly, you can apply the same tag to multiple resources if you want to specify a relationship among those resources. For example, you can add the same tag to an ACM certificate and an Elastic Load Balancing load balancer to indicate that they are both used by the same website. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/tags.html">Tagging ACM certificates</a>. </p> <p>To remove one or more tags, use the <a>RemoveTagsFromCertificate</a> action. To view all of the tags that have been applied to the certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "CertificateManager.AddTagsToCertificate"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_AddTagsToCertificate_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to an ACM certificate. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a <code>key</code> and an optional <code>value</code>. You specify the certificate on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. </p> <p>You can apply a tag to just one certificate if you want to identify a specific characteristic of that certificate, or you can apply the same tag to multiple certificates if you want to filter for a common relationship among those certificates. Similarly, you can apply the same tag to multiple resources if you want to specify a relationship among those resources. For example, you can add the same tag to an ACM certificate and an Elastic Load Balancing load balancer to indicate that they are both used by the same website. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/tags.html">Tagging ACM certificates</a>. </p> <p>To remove one or more tags, use the <a>RemoveTagsFromCertificate</a> action. To view all of the tags that have been applied to the certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AddTagsToCertificate_772933; body: JsonNode): Recallable =
  ## addTagsToCertificate
  ## <p>Adds one or more tags to an ACM certificate. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a <code>key</code> and an optional <code>value</code>. You specify the certificate on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. </p> <p>You can apply a tag to just one certificate if you want to identify a specific characteristic of that certificate, or you can apply the same tag to multiple certificates if you want to filter for a common relationship among those certificates. Similarly, you can apply the same tag to multiple resources if you want to specify a relationship among those resources. For example, you can add the same tag to an ACM certificate and an Elastic Load Balancing load balancer to indicate that they are both used by the same website. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/tags.html">Tagging ACM certificates</a>. </p> <p>To remove one or more tags, use the <a>RemoveTagsFromCertificate</a> action. To view all of the tags that have been applied to the certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var addTagsToCertificate* = Call_AddTagsToCertificate_772933(
    name: "addTagsToCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.AddTagsToCertificate",
    validator: validate_AddTagsToCertificate_772934, base: "/",
    url: url_AddTagsToCertificate_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_773202 = ref object of OpenApiRestCall_772597
proc url_DeleteCertificate_773204(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCertificate_773203(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a certificate and its associated private key. If this action succeeds, the certificate no longer appears in the list that can be displayed by calling the <a>ListCertificates</a> action or be retrieved by calling the <a>GetCertificate</a> action. The certificate will not be available for use by AWS services integrated with ACM. </p> <note> <p>You cannot delete an ACM certificate that is being used by another AWS service. To delete a certificate that is in use, the certificate association must first be removed.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "CertificateManager.DeleteCertificate"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_DeleteCertificate_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a certificate and its associated private key. If this action succeeds, the certificate no longer appears in the list that can be displayed by calling the <a>ListCertificates</a> action or be retrieved by calling the <a>GetCertificate</a> action. The certificate will not be available for use by AWS services integrated with ACM. </p> <note> <p>You cannot delete an ACM certificate that is being used by another AWS service. To delete a certificate that is in use, the certificate association must first be removed.</p> </note>
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_DeleteCertificate_773202; body: JsonNode): Recallable =
  ## deleteCertificate
  ## <p>Deletes a certificate and its associated private key. If this action succeeds, the certificate no longer appears in the list that can be displayed by calling the <a>ListCertificates</a> action or be retrieved by calling the <a>GetCertificate</a> action. The certificate will not be available for use by AWS services integrated with ACM. </p> <note> <p>You cannot delete an ACM certificate that is being used by another AWS service. To delete a certificate that is in use, the certificate association must first be removed.</p> </note>
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var deleteCertificate* = Call_DeleteCertificate_773202(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.DeleteCertificate",
    validator: validate_DeleteCertificate_773203, base: "/",
    url: url_DeleteCertificate_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificate_773217 = ref object of OpenApiRestCall_772597
proc url_DescribeCertificate_773219(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCertificate_773218(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns detailed metadata about the specified ACM certificate.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "CertificateManager.DescribeCertificate"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_DescribeCertificate_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about the specified ACM certificate.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_DescribeCertificate_773217; body: JsonNode): Recallable =
  ## describeCertificate
  ## Returns detailed metadata about the specified ACM certificate.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var describeCertificate* = Call_DescribeCertificate_773217(
    name: "describeCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.DescribeCertificate",
    validator: validate_DescribeCertificate_773218, base: "/",
    url: url_DescribeCertificate_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportCertificate_773232 = ref object of OpenApiRestCall_772597
proc url_ExportCertificate_773234(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExportCertificate_773233(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Exports a private certificate issued by a private certificate authority (CA) for use anywhere. You can export the certificate, the certificate chain, and the encrypted private key associated with the public key embedded in the certificate. You must store the private key securely. The private key is a 2048 bit RSA key. You must provide a passphrase for the private key when exporting it. You can use the following OpenSSL command to decrypt it later. Provide the passphrase when prompted. </p> <p> <code>openssl rsa -in encrypted_key.pem -out decrypted_key.pem</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "CertificateManager.ExportCertificate"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_ExportCertificate_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports a private certificate issued by a private certificate authority (CA) for use anywhere. You can export the certificate, the certificate chain, and the encrypted private key associated with the public key embedded in the certificate. You must store the private key securely. The private key is a 2048 bit RSA key. You must provide a passphrase for the private key when exporting it. You can use the following OpenSSL command to decrypt it later. Provide the passphrase when prompted. </p> <p> <code>openssl rsa -in encrypted_key.pem -out decrypted_key.pem</code> </p>
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_ExportCertificate_773232; body: JsonNode): Recallable =
  ## exportCertificate
  ## <p>Exports a private certificate issued by a private certificate authority (CA) for use anywhere. You can export the certificate, the certificate chain, and the encrypted private key associated with the public key embedded in the certificate. You must store the private key securely. The private key is a 2048 bit RSA key. You must provide a passphrase for the private key when exporting it. You can use the following OpenSSL command to decrypt it later. Provide the passphrase when prompted. </p> <p> <code>openssl rsa -in encrypted_key.pem -out decrypted_key.pem</code> </p>
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var exportCertificate* = Call_ExportCertificate_773232(name: "exportCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ExportCertificate",
    validator: validate_ExportCertificate_773233, base: "/",
    url: url_ExportCertificate_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificate_773247 = ref object of OpenApiRestCall_772597
proc url_GetCertificate_773249(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCertificate_773248(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a certificate specified by an ARN and its certificate chain . The chain is an ordered list of certificates that contains the end entity certificate, intermediate certificates of subordinate CAs, and the root certificate in that order. The certificate and certificate chain are base64 encoded. If you want to decode the certificate to see the individual fields, you can use OpenSSL.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "CertificateManager.GetCertificate"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_GetCertificate_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a certificate specified by an ARN and its certificate chain . The chain is an ordered list of certificates that contains the end entity certificate, intermediate certificates of subordinate CAs, and the root certificate in that order. The certificate and certificate chain are base64 encoded. If you want to decode the certificate to see the individual fields, you can use OpenSSL.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_GetCertificate_773247; body: JsonNode): Recallable =
  ## getCertificate
  ## Retrieves a certificate specified by an ARN and its certificate chain . The chain is an ordered list of certificates that contains the end entity certificate, intermediate certificates of subordinate CAs, and the root certificate in that order. The certificate and certificate chain are base64 encoded. If you want to decode the certificate to see the individual fields, you can use OpenSSL.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var getCertificate* = Call_GetCertificate_773247(name: "getCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.GetCertificate",
    validator: validate_GetCertificate_773248, base: "/", url: url_GetCertificate_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_773262 = ref object of OpenApiRestCall_772597
proc url_ImportCertificate_773264(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportCertificate_773263(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Imports a certificate into AWS Certificate Manager (ACM) to use with services that are integrated with ACM. Note that <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html">integrated services</a> allow only certificate types and keys they support to be associated with their resources. Further, their support differs depending on whether the certificate is imported into IAM or into ACM. For more information, see the documentation for each service. For more information about importing certificates into ACM, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html">Importing Certificates</a> in the <i>AWS Certificate Manager User Guide</i>. </p> <note> <p>ACM does not provide <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-renewal.html">managed renewal</a> for certificates that you import.</p> </note> <p>Note the following guidelines when importing third party certificates:</p> <ul> <li> <p>You must enter the private key that matches the certificate you are importing.</p> </li> <li> <p>The private key must be unencrypted. You cannot import a private key that is protected by a password or a passphrase.</p> </li> <li> <p>If the certificate you are importing is not self-signed, you must enter its certificate chain.</p> </li> <li> <p>If a certificate chain is included, the issuer must be the subject of one of the certificates in the chain.</p> </li> <li> <p>The certificate, private key, and certificate chain must be PEM-encoded.</p> </li> <li> <p>The current time must be between the <code>Not Before</code> and <code>Not After</code> certificate fields.</p> </li> <li> <p>The <code>Issuer</code> field must not be empty.</p> </li> <li> <p>The OCSP authority URL, if present, must not exceed 1000 characters.</p> </li> <li> <p>To import a new certificate, omit the <code>CertificateArn</code> argument. Include this argument only when you want to replace a previously imported certificate.</p> </li> <li> <p>When you import a certificate by using the CLI, you must specify the certificate, the certificate chain, and the private key by their file names preceded by <code>file://</code>. For example, you can specify a certificate saved in the <code>C:\temp</code> folder as <code>file://C:\temp\certificate_to_import.pem</code>. If you are making an HTTP or HTTPS Query request, include these arguments as BLOBs. </p> </li> <li> <p>When you import a certificate by using an SDK, you must specify the certificate, the certificate chain, and the private key files in the manner required by the programming language you're using. </p> </li> </ul> <p>This operation returns the <a href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Name (ARN)</a> of the imported certificate.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "CertificateManager.ImportCertificate"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_ImportCertificate_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports a certificate into AWS Certificate Manager (ACM) to use with services that are integrated with ACM. Note that <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html">integrated services</a> allow only certificate types and keys they support to be associated with their resources. Further, their support differs depending on whether the certificate is imported into IAM or into ACM. For more information, see the documentation for each service. For more information about importing certificates into ACM, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html">Importing Certificates</a> in the <i>AWS Certificate Manager User Guide</i>. </p> <note> <p>ACM does not provide <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-renewal.html">managed renewal</a> for certificates that you import.</p> </note> <p>Note the following guidelines when importing third party certificates:</p> <ul> <li> <p>You must enter the private key that matches the certificate you are importing.</p> </li> <li> <p>The private key must be unencrypted. You cannot import a private key that is protected by a password or a passphrase.</p> </li> <li> <p>If the certificate you are importing is not self-signed, you must enter its certificate chain.</p> </li> <li> <p>If a certificate chain is included, the issuer must be the subject of one of the certificates in the chain.</p> </li> <li> <p>The certificate, private key, and certificate chain must be PEM-encoded.</p> </li> <li> <p>The current time must be between the <code>Not Before</code> and <code>Not After</code> certificate fields.</p> </li> <li> <p>The <code>Issuer</code> field must not be empty.</p> </li> <li> <p>The OCSP authority URL, if present, must not exceed 1000 characters.</p> </li> <li> <p>To import a new certificate, omit the <code>CertificateArn</code> argument. Include this argument only when you want to replace a previously imported certificate.</p> </li> <li> <p>When you import a certificate by using the CLI, you must specify the certificate, the certificate chain, and the private key by their file names preceded by <code>file://</code>. For example, you can specify a certificate saved in the <code>C:\temp</code> folder as <code>file://C:\temp\certificate_to_import.pem</code>. If you are making an HTTP or HTTPS Query request, include these arguments as BLOBs. </p> </li> <li> <p>When you import a certificate by using an SDK, you must specify the certificate, the certificate chain, and the private key files in the manner required by the programming language you're using. </p> </li> </ul> <p>This operation returns the <a href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Name (ARN)</a> of the imported certificate.</p>
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_ImportCertificate_773262; body: JsonNode): Recallable =
  ## importCertificate
  ## <p>Imports a certificate into AWS Certificate Manager (ACM) to use with services that are integrated with ACM. Note that <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html">integrated services</a> allow only certificate types and keys they support to be associated with their resources. Further, their support differs depending on whether the certificate is imported into IAM or into ACM. For more information, see the documentation for each service. For more information about importing certificates into ACM, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html">Importing Certificates</a> in the <i>AWS Certificate Manager User Guide</i>. </p> <note> <p>ACM does not provide <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-renewal.html">managed renewal</a> for certificates that you import.</p> </note> <p>Note the following guidelines when importing third party certificates:</p> <ul> <li> <p>You must enter the private key that matches the certificate you are importing.</p> </li> <li> <p>The private key must be unencrypted. You cannot import a private key that is protected by a password or a passphrase.</p> </li> <li> <p>If the certificate you are importing is not self-signed, you must enter its certificate chain.</p> </li> <li> <p>If a certificate chain is included, the issuer must be the subject of one of the certificates in the chain.</p> </li> <li> <p>The certificate, private key, and certificate chain must be PEM-encoded.</p> </li> <li> <p>The current time must be between the <code>Not Before</code> and <code>Not After</code> certificate fields.</p> </li> <li> <p>The <code>Issuer</code> field must not be empty.</p> </li> <li> <p>The OCSP authority URL, if present, must not exceed 1000 characters.</p> </li> <li> <p>To import a new certificate, omit the <code>CertificateArn</code> argument. Include this argument only when you want to replace a previously imported certificate.</p> </li> <li> <p>When you import a certificate by using the CLI, you must specify the certificate, the certificate chain, and the private key by their file names preceded by <code>file://</code>. For example, you can specify a certificate saved in the <code>C:\temp</code> folder as <code>file://C:\temp\certificate_to_import.pem</code>. If you are making an HTTP or HTTPS Query request, include these arguments as BLOBs. </p> </li> <li> <p>When you import a certificate by using an SDK, you must specify the certificate, the certificate chain, and the private key files in the manner required by the programming language you're using. </p> </li> </ul> <p>This operation returns the <a href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Name (ARN)</a> of the imported certificate.</p>
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var importCertificate* = Call_ImportCertificate_773262(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ImportCertificate",
    validator: validate_ImportCertificate_773263, base: "/",
    url: url_ImportCertificate_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificates_773277 = ref object of OpenApiRestCall_772597
proc url_ListCertificates_773279(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCertificates_773278(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of certificate ARNs and domain names. You can request that only certificates that match a specific status be listed. You can also filter by specific attributes of the certificate. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773280 = query.getOrDefault("NextToken")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "NextToken", valid_773280
  var valid_773281 = query.getOrDefault("MaxItems")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "MaxItems", valid_773281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773282 = header.getOrDefault("X-Amz-Date")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Date", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Security-Token")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Security-Token", valid_773283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773284 = header.getOrDefault("X-Amz-Target")
  valid_773284 = validateParameter(valid_773284, JString, required = true, default = newJString(
      "CertificateManager.ListCertificates"))
  if valid_773284 != nil:
    section.add "X-Amz-Target", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Content-Sha256", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Algorithm")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Algorithm", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Signature")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Signature", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-SignedHeaders", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Credential")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Credential", valid_773289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773291: Call_ListCertificates_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of certificate ARNs and domain names. You can request that only certificates that match a specific status be listed. You can also filter by specific attributes of the certificate. 
  ## 
  let valid = call_773291.validator(path, query, header, formData, body)
  let scheme = call_773291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773291.url(scheme.get, call_773291.host, call_773291.base,
                         call_773291.route, valid.getOrDefault("path"))
  result = hook(call_773291, url, valid)

proc call*(call_773292: Call_ListCertificates_773277; body: JsonNode;
          NextToken: string = ""; MaxItems: string = ""): Recallable =
  ## listCertificates
  ## Retrieves a list of certificate ARNs and domain names. You can request that only certificates that match a specific status be listed. You can also filter by specific attributes of the certificate. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_773293 = newJObject()
  var body_773294 = newJObject()
  add(query_773293, "NextToken", newJString(NextToken))
  if body != nil:
    body_773294 = body
  add(query_773293, "MaxItems", newJString(MaxItems))
  result = call_773292.call(nil, query_773293, nil, nil, body_773294)

var listCertificates* = Call_ListCertificates_773277(name: "listCertificates",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ListCertificates",
    validator: validate_ListCertificates_773278, base: "/",
    url: url_ListCertificates_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForCertificate_773296 = ref object of OpenApiRestCall_772597
proc url_ListTagsForCertificate_773298(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForCertificate_773297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags that have been applied to the ACM certificate. Use the certificate's Amazon Resource Name (ARN) to specify the certificate. To add a tag to an ACM certificate, use the <a>AddTagsToCertificate</a> action. To delete a tag, use the <a>RemoveTagsFromCertificate</a> action. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773299 = header.getOrDefault("X-Amz-Date")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Date", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Security-Token")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Security-Token", valid_773300
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773301 = header.getOrDefault("X-Amz-Target")
  valid_773301 = validateParameter(valid_773301, JString, required = true, default = newJString(
      "CertificateManager.ListTagsForCertificate"))
  if valid_773301 != nil:
    section.add "X-Amz-Target", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Content-Sha256", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Algorithm")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Algorithm", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Signature")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Signature", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-SignedHeaders", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Credential")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Credential", valid_773306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773308: Call_ListTagsForCertificate_773296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that have been applied to the ACM certificate. Use the certificate's Amazon Resource Name (ARN) to specify the certificate. To add a tag to an ACM certificate, use the <a>AddTagsToCertificate</a> action. To delete a tag, use the <a>RemoveTagsFromCertificate</a> action. 
  ## 
  let valid = call_773308.validator(path, query, header, formData, body)
  let scheme = call_773308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773308.url(scheme.get, call_773308.host, call_773308.base,
                         call_773308.route, valid.getOrDefault("path"))
  result = hook(call_773308, url, valid)

proc call*(call_773309: Call_ListTagsForCertificate_773296; body: JsonNode): Recallable =
  ## listTagsForCertificate
  ## Lists the tags that have been applied to the ACM certificate. Use the certificate's Amazon Resource Name (ARN) to specify the certificate. To add a tag to an ACM certificate, use the <a>AddTagsToCertificate</a> action. To delete a tag, use the <a>RemoveTagsFromCertificate</a> action. 
  ##   body: JObject (required)
  var body_773310 = newJObject()
  if body != nil:
    body_773310 = body
  result = call_773309.call(nil, nil, nil, nil, body_773310)

var listTagsForCertificate* = Call_ListTagsForCertificate_773296(
    name: "listTagsForCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ListTagsForCertificate",
    validator: validate_ListTagsForCertificate_773297, base: "/",
    url: url_ListTagsForCertificate_773298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromCertificate_773311 = ref object of OpenApiRestCall_772597
proc url_RemoveTagsFromCertificate_773313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromCertificate_773312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Remove one or more tags from an ACM certificate. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this function, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. </p> <p>To add tags to a certificate, use the <a>AddTagsToCertificate</a> action. To view all of the tags that have been applied to a specific ACM certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773314 = header.getOrDefault("X-Amz-Date")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Date", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Security-Token")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Security-Token", valid_773315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773316 = header.getOrDefault("X-Amz-Target")
  valid_773316 = validateParameter(valid_773316, JString, required = true, default = newJString(
      "CertificateManager.RemoveTagsFromCertificate"))
  if valid_773316 != nil:
    section.add "X-Amz-Target", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Content-Sha256", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Algorithm")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Algorithm", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Signature")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Signature", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-SignedHeaders", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Credential")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Credential", valid_773321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773323: Call_RemoveTagsFromCertificate_773311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove one or more tags from an ACM certificate. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this function, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. </p> <p>To add tags to a certificate, use the <a>AddTagsToCertificate</a> action. To view all of the tags that have been applied to a specific ACM certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  let valid = call_773323.validator(path, query, header, formData, body)
  let scheme = call_773323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773323.url(scheme.get, call_773323.host, call_773323.base,
                         call_773323.route, valid.getOrDefault("path"))
  result = hook(call_773323, url, valid)

proc call*(call_773324: Call_RemoveTagsFromCertificate_773311; body: JsonNode): Recallable =
  ## removeTagsFromCertificate
  ## <p>Remove one or more tags from an ACM certificate. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this function, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. </p> <p>To add tags to a certificate, use the <a>AddTagsToCertificate</a> action. To view all of the tags that have been applied to a specific ACM certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ##   body: JObject (required)
  var body_773325 = newJObject()
  if body != nil:
    body_773325 = body
  result = call_773324.call(nil, nil, nil, nil, body_773325)

var removeTagsFromCertificate* = Call_RemoveTagsFromCertificate_773311(
    name: "removeTagsFromCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RemoveTagsFromCertificate",
    validator: validate_RemoveTagsFromCertificate_773312, base: "/",
    url: url_RemoveTagsFromCertificate_773313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewCertificate_773326 = ref object of OpenApiRestCall_772597
proc url_RenewCertificate_773328(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RenewCertificate_773327(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Renews an eligable ACM certificate. At this time, only exported private certificates can be renewed with this operation. In order to renew your ACM PCA certificates with ACM, you must first <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaPermissions.html">grant the ACM service principal permission to do so</a>. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/manual-renewal.html">Testing Managed Renewal</a> in the ACM User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773329 = header.getOrDefault("X-Amz-Date")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Date", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Security-Token")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Security-Token", valid_773330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773331 = header.getOrDefault("X-Amz-Target")
  valid_773331 = validateParameter(valid_773331, JString, required = true, default = newJString(
      "CertificateManager.RenewCertificate"))
  if valid_773331 != nil:
    section.add "X-Amz-Target", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Content-Sha256", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Algorithm")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Algorithm", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Signature")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Signature", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-SignedHeaders", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Credential")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Credential", valid_773336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773338: Call_RenewCertificate_773326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renews an eligable ACM certificate. At this time, only exported private certificates can be renewed with this operation. In order to renew your ACM PCA certificates with ACM, you must first <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaPermissions.html">grant the ACM service principal permission to do so</a>. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/manual-renewal.html">Testing Managed Renewal</a> in the ACM User Guide.
  ## 
  let valid = call_773338.validator(path, query, header, formData, body)
  let scheme = call_773338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773338.url(scheme.get, call_773338.host, call_773338.base,
                         call_773338.route, valid.getOrDefault("path"))
  result = hook(call_773338, url, valid)

proc call*(call_773339: Call_RenewCertificate_773326; body: JsonNode): Recallable =
  ## renewCertificate
  ## Renews an eligable ACM certificate. At this time, only exported private certificates can be renewed with this operation. In order to renew your ACM PCA certificates with ACM, you must first <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaPermissions.html">grant the ACM service principal permission to do so</a>. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/manual-renewal.html">Testing Managed Renewal</a> in the ACM User Guide.
  ##   body: JObject (required)
  var body_773340 = newJObject()
  if body != nil:
    body_773340 = body
  result = call_773339.call(nil, nil, nil, nil, body_773340)

var renewCertificate* = Call_RenewCertificate_773326(name: "renewCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RenewCertificate",
    validator: validate_RenewCertificate_773327, base: "/",
    url: url_RenewCertificate_773328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestCertificate_773341 = ref object of OpenApiRestCall_772597
proc url_RequestCertificate_773343(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RequestCertificate_773342(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Requests an ACM certificate for use with other AWS services. To request an ACM certificate, you must specify a fully qualified domain name (FQDN) in the <code>DomainName</code> parameter. You can also specify additional FQDNs in the <code>SubjectAlternativeNames</code> parameter. </p> <p>If you are requesting a private certificate, domain validation is not required. If you are requesting a public certificate, each domain name that you specify must be validated to verify that you own or control the domain. You can use <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html">DNS validation</a> or <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-email.html">email validation</a>. We recommend that you use DNS validation. ACM issues public certificates after receiving approval from the domain owner. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773344 = header.getOrDefault("X-Amz-Date")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Date", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Security-Token")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Security-Token", valid_773345
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773346 = header.getOrDefault("X-Amz-Target")
  valid_773346 = validateParameter(valid_773346, JString, required = true, default = newJString(
      "CertificateManager.RequestCertificate"))
  if valid_773346 != nil:
    section.add "X-Amz-Target", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Content-Sha256", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Algorithm")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Algorithm", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Signature")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Signature", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-SignedHeaders", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Credential")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Credential", valid_773351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773353: Call_RequestCertificate_773341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests an ACM certificate for use with other AWS services. To request an ACM certificate, you must specify a fully qualified domain name (FQDN) in the <code>DomainName</code> parameter. You can also specify additional FQDNs in the <code>SubjectAlternativeNames</code> parameter. </p> <p>If you are requesting a private certificate, domain validation is not required. If you are requesting a public certificate, each domain name that you specify must be validated to verify that you own or control the domain. You can use <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html">DNS validation</a> or <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-email.html">email validation</a>. We recommend that you use DNS validation. ACM issues public certificates after receiving approval from the domain owner. </p>
  ## 
  let valid = call_773353.validator(path, query, header, formData, body)
  let scheme = call_773353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773353.url(scheme.get, call_773353.host, call_773353.base,
                         call_773353.route, valid.getOrDefault("path"))
  result = hook(call_773353, url, valid)

proc call*(call_773354: Call_RequestCertificate_773341; body: JsonNode): Recallable =
  ## requestCertificate
  ## <p>Requests an ACM certificate for use with other AWS services. To request an ACM certificate, you must specify a fully qualified domain name (FQDN) in the <code>DomainName</code> parameter. You can also specify additional FQDNs in the <code>SubjectAlternativeNames</code> parameter. </p> <p>If you are requesting a private certificate, domain validation is not required. If you are requesting a public certificate, each domain name that you specify must be validated to verify that you own or control the domain. You can use <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html">DNS validation</a> or <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-email.html">email validation</a>. We recommend that you use DNS validation. ACM issues public certificates after receiving approval from the domain owner. </p>
  ##   body: JObject (required)
  var body_773355 = newJObject()
  if body != nil:
    body_773355 = body
  result = call_773354.call(nil, nil, nil, nil, body_773355)

var requestCertificate* = Call_RequestCertificate_773341(
    name: "requestCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RequestCertificate",
    validator: validate_RequestCertificate_773342, base: "/",
    url: url_RequestCertificate_773343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendValidationEmail_773356 = ref object of OpenApiRestCall_772597
proc url_ResendValidationEmail_773358(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResendValidationEmail_773357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Resends the email that requests domain ownership validation. The domain owner or an authorized representative must approve the ACM certificate before it can be issued. The certificate can be approved by clicking a link in the mail to navigate to the Amazon certificate approval website and then clicking <b>I Approve</b>. However, the validation email can be blocked by spam filters. Therefore, if you do not receive the original mail, you can request that the mail be resent within 72 hours of requesting the ACM certificate. If more than 72 hours have elapsed since your original request or since your last attempt to resend validation mail, you must request a new certificate. For more information about setting up your contact email addresses, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/setup-email.html">Configure Email for your Domain</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773359 = header.getOrDefault("X-Amz-Date")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Date", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Security-Token")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Security-Token", valid_773360
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773361 = header.getOrDefault("X-Amz-Target")
  valid_773361 = validateParameter(valid_773361, JString, required = true, default = newJString(
      "CertificateManager.ResendValidationEmail"))
  if valid_773361 != nil:
    section.add "X-Amz-Target", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Content-Sha256", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Algorithm")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Algorithm", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Signature")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Signature", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-SignedHeaders", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Credential")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Credential", valid_773366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773368: Call_ResendValidationEmail_773356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the email that requests domain ownership validation. The domain owner or an authorized representative must approve the ACM certificate before it can be issued. The certificate can be approved by clicking a link in the mail to navigate to the Amazon certificate approval website and then clicking <b>I Approve</b>. However, the validation email can be blocked by spam filters. Therefore, if you do not receive the original mail, you can request that the mail be resent within 72 hours of requesting the ACM certificate. If more than 72 hours have elapsed since your original request or since your last attempt to resend validation mail, you must request a new certificate. For more information about setting up your contact email addresses, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/setup-email.html">Configure Email for your Domain</a>. 
  ## 
  let valid = call_773368.validator(path, query, header, formData, body)
  let scheme = call_773368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773368.url(scheme.get, call_773368.host, call_773368.base,
                         call_773368.route, valid.getOrDefault("path"))
  result = hook(call_773368, url, valid)

proc call*(call_773369: Call_ResendValidationEmail_773356; body: JsonNode): Recallable =
  ## resendValidationEmail
  ## Resends the email that requests domain ownership validation. The domain owner or an authorized representative must approve the ACM certificate before it can be issued. The certificate can be approved by clicking a link in the mail to navigate to the Amazon certificate approval website and then clicking <b>I Approve</b>. However, the validation email can be blocked by spam filters. Therefore, if you do not receive the original mail, you can request that the mail be resent within 72 hours of requesting the ACM certificate. If more than 72 hours have elapsed since your original request or since your last attempt to resend validation mail, you must request a new certificate. For more information about setting up your contact email addresses, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/setup-email.html">Configure Email for your Domain</a>. 
  ##   body: JObject (required)
  var body_773370 = newJObject()
  if body != nil:
    body_773370 = body
  result = call_773369.call(nil, nil, nil, nil, body_773370)

var resendValidationEmail* = Call_ResendValidationEmail_773356(
    name: "resendValidationEmail", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ResendValidationEmail",
    validator: validate_ResendValidationEmail_773357, base: "/",
    url: url_ResendValidationEmail_773358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCertificateOptions_773371 = ref object of OpenApiRestCall_772597
proc url_UpdateCertificateOptions_773373(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCertificateOptions_773372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a certificate. Currently, you can use this function to specify whether to opt in to or out of recording your certificate in a certificate transparency log. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-bestpractices.html#best-practices-transparency"> Opting Out of Certificate Transparency Logging</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773374 = header.getOrDefault("X-Amz-Date")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Date", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Security-Token")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Security-Token", valid_773375
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773376 = header.getOrDefault("X-Amz-Target")
  valid_773376 = validateParameter(valid_773376, JString, required = true, default = newJString(
      "CertificateManager.UpdateCertificateOptions"))
  if valid_773376 != nil:
    section.add "X-Amz-Target", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Content-Sha256", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Algorithm")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Algorithm", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Signature")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Signature", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-SignedHeaders", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Credential")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Credential", valid_773381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773383: Call_UpdateCertificateOptions_773371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a certificate. Currently, you can use this function to specify whether to opt in to or out of recording your certificate in a certificate transparency log. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-bestpractices.html#best-practices-transparency"> Opting Out of Certificate Transparency Logging</a>. 
  ## 
  let valid = call_773383.validator(path, query, header, formData, body)
  let scheme = call_773383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773383.url(scheme.get, call_773383.host, call_773383.base,
                         call_773383.route, valid.getOrDefault("path"))
  result = hook(call_773383, url, valid)

proc call*(call_773384: Call_UpdateCertificateOptions_773371; body: JsonNode): Recallable =
  ## updateCertificateOptions
  ## Updates a certificate. Currently, you can use this function to specify whether to opt in to or out of recording your certificate in a certificate transparency log. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-bestpractices.html#best-practices-transparency"> Opting Out of Certificate Transparency Logging</a>. 
  ##   body: JObject (required)
  var body_773385 = newJObject()
  if body != nil:
    body_773385 = body
  result = call_773384.call(nil, nil, nil, nil, body_773385)

var updateCertificateOptions* = Call_UpdateCertificateOptions_773371(
    name: "updateCertificateOptions", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.UpdateCertificateOptions",
    validator: validate_UpdateCertificateOptions_773372, base: "/",
    url: url_UpdateCertificateOptions_773373, schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
