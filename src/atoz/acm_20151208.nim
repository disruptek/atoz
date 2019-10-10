
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  result = some(head & remainder.get)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToCertificate_602803 = ref object of OpenApiRestCall_602466
proc url_AddTagsToCertificate_602805(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToCertificate_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "CertificateManager.AddTagsToCertificate"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AddTagsToCertificate_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to an ACM certificate. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a <code>key</code> and an optional <code>value</code>. You specify the certificate on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. </p> <p>You can apply a tag to just one certificate if you want to identify a specific characteristic of that certificate, or you can apply the same tag to multiple certificates if you want to filter for a common relationship among those certificates. Similarly, you can apply the same tag to multiple resources if you want to specify a relationship among those resources. For example, you can add the same tag to an ACM certificate and an Elastic Load Balancing load balancer to indicate that they are both used by the same website. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/tags.html">Tagging ACM certificates</a>. </p> <p>To remove one or more tags, use the <a>RemoveTagsFromCertificate</a> action. To view all of the tags that have been applied to the certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AddTagsToCertificate_602803; body: JsonNode): Recallable =
  ## addTagsToCertificate
  ## <p>Adds one or more tags to an ACM certificate. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a <code>key</code> and an optional <code>value</code>. You specify the certificate on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. </p> <p>You can apply a tag to just one certificate if you want to identify a specific characteristic of that certificate, or you can apply the same tag to multiple certificates if you want to filter for a common relationship among those certificates. Similarly, you can apply the same tag to multiple resources if you want to specify a relationship among those resources. For example, you can add the same tag to an ACM certificate and an Elastic Load Balancing load balancer to indicate that they are both used by the same website. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/tags.html">Tagging ACM certificates</a>. </p> <p>To remove one or more tags, use the <a>RemoveTagsFromCertificate</a> action. To view all of the tags that have been applied to the certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var addTagsToCertificate* = Call_AddTagsToCertificate_602803(
    name: "addTagsToCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.AddTagsToCertificate",
    validator: validate_AddTagsToCertificate_602804, base: "/",
    url: url_AddTagsToCertificate_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_603072 = ref object of OpenApiRestCall_602466
proc url_DeleteCertificate_603074(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCertificate_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "CertificateManager.DeleteCertificate"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_DeleteCertificate_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a certificate and its associated private key. If this action succeeds, the certificate no longer appears in the list that can be displayed by calling the <a>ListCertificates</a> action or be retrieved by calling the <a>GetCertificate</a> action. The certificate will not be available for use by AWS services integrated with ACM. </p> <note> <p>You cannot delete an ACM certificate that is being used by another AWS service. To delete a certificate that is in use, the certificate association must first be removed.</p> </note>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_DeleteCertificate_603072; body: JsonNode): Recallable =
  ## deleteCertificate
  ## <p>Deletes a certificate and its associated private key. If this action succeeds, the certificate no longer appears in the list that can be displayed by calling the <a>ListCertificates</a> action or be retrieved by calling the <a>GetCertificate</a> action. The certificate will not be available for use by AWS services integrated with ACM. </p> <note> <p>You cannot delete an ACM certificate that is being used by another AWS service. To delete a certificate that is in use, the certificate association must first be removed.</p> </note>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var deleteCertificate* = Call_DeleteCertificate_603072(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.DeleteCertificate",
    validator: validate_DeleteCertificate_603073, base: "/",
    url: url_DeleteCertificate_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificate_603087 = ref object of OpenApiRestCall_602466
proc url_DescribeCertificate_603089(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCertificate_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "CertificateManager.DescribeCertificate"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_DescribeCertificate_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about the specified ACM certificate.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_DescribeCertificate_603087; body: JsonNode): Recallable =
  ## describeCertificate
  ## Returns detailed metadata about the specified ACM certificate.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var describeCertificate* = Call_DescribeCertificate_603087(
    name: "describeCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.DescribeCertificate",
    validator: validate_DescribeCertificate_603088, base: "/",
    url: url_DescribeCertificate_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportCertificate_603102 = ref object of OpenApiRestCall_602466
proc url_ExportCertificate_603104(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExportCertificate_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "CertificateManager.ExportCertificate"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_ExportCertificate_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports a private certificate issued by a private certificate authority (CA) for use anywhere. You can export the certificate, the certificate chain, and the encrypted private key associated with the public key embedded in the certificate. You must store the private key securely. The private key is a 2048 bit RSA key. You must provide a passphrase for the private key when exporting it. You can use the following OpenSSL command to decrypt it later. Provide the passphrase when prompted. </p> <p> <code>openssl rsa -in encrypted_key.pem -out decrypted_key.pem</code> </p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_ExportCertificate_603102; body: JsonNode): Recallable =
  ## exportCertificate
  ## <p>Exports a private certificate issued by a private certificate authority (CA) for use anywhere. You can export the certificate, the certificate chain, and the encrypted private key associated with the public key embedded in the certificate. You must store the private key securely. The private key is a 2048 bit RSA key. You must provide a passphrase for the private key when exporting it. You can use the following OpenSSL command to decrypt it later. Provide the passphrase when prompted. </p> <p> <code>openssl rsa -in encrypted_key.pem -out decrypted_key.pem</code> </p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var exportCertificate* = Call_ExportCertificate_603102(name: "exportCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ExportCertificate",
    validator: validate_ExportCertificate_603103, base: "/",
    url: url_ExportCertificate_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificate_603117 = ref object of OpenApiRestCall_602466
proc url_GetCertificate_603119(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCertificate_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "CertificateManager.GetCertificate"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_GetCertificate_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a certificate specified by an ARN and its certificate chain . The chain is an ordered list of certificates that contains the end entity certificate, intermediate certificates of subordinate CAs, and the root certificate in that order. The certificate and certificate chain are base64 encoded. If you want to decode the certificate to see the individual fields, you can use OpenSSL.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_GetCertificate_603117; body: JsonNode): Recallable =
  ## getCertificate
  ## Retrieves a certificate specified by an ARN and its certificate chain . The chain is an ordered list of certificates that contains the end entity certificate, intermediate certificates of subordinate CAs, and the root certificate in that order. The certificate and certificate chain are base64 encoded. If you want to decode the certificate to see the individual fields, you can use OpenSSL.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var getCertificate* = Call_GetCertificate_603117(name: "getCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.GetCertificate",
    validator: validate_GetCertificate_603118, base: "/", url: url_GetCertificate_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_603132 = ref object of OpenApiRestCall_602466
proc url_ImportCertificate_603134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCertificate_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "CertificateManager.ImportCertificate"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_ImportCertificate_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports a certificate into AWS Certificate Manager (ACM) to use with services that are integrated with ACM. Note that <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html">integrated services</a> allow only certificate types and keys they support to be associated with their resources. Further, their support differs depending on whether the certificate is imported into IAM or into ACM. For more information, see the documentation for each service. For more information about importing certificates into ACM, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html">Importing Certificates</a> in the <i>AWS Certificate Manager User Guide</i>. </p> <note> <p>ACM does not provide <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-renewal.html">managed renewal</a> for certificates that you import.</p> </note> <p>Note the following guidelines when importing third party certificates:</p> <ul> <li> <p>You must enter the private key that matches the certificate you are importing.</p> </li> <li> <p>The private key must be unencrypted. You cannot import a private key that is protected by a password or a passphrase.</p> </li> <li> <p>If the certificate you are importing is not self-signed, you must enter its certificate chain.</p> </li> <li> <p>If a certificate chain is included, the issuer must be the subject of one of the certificates in the chain.</p> </li> <li> <p>The certificate, private key, and certificate chain must be PEM-encoded.</p> </li> <li> <p>The current time must be between the <code>Not Before</code> and <code>Not After</code> certificate fields.</p> </li> <li> <p>The <code>Issuer</code> field must not be empty.</p> </li> <li> <p>The OCSP authority URL, if present, must not exceed 1000 characters.</p> </li> <li> <p>To import a new certificate, omit the <code>CertificateArn</code> argument. Include this argument only when you want to replace a previously imported certificate.</p> </li> <li> <p>When you import a certificate by using the CLI, you must specify the certificate, the certificate chain, and the private key by their file names preceded by <code>file://</code>. For example, you can specify a certificate saved in the <code>C:\temp</code> folder as <code>file://C:\temp\certificate_to_import.pem</code>. If you are making an HTTP or HTTPS Query request, include these arguments as BLOBs. </p> </li> <li> <p>When you import a certificate by using an SDK, you must specify the certificate, the certificate chain, and the private key files in the manner required by the programming language you're using. </p> </li> </ul> <p>This operation returns the <a href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Name (ARN)</a> of the imported certificate.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_ImportCertificate_603132; body: JsonNode): Recallable =
  ## importCertificate
  ## <p>Imports a certificate into AWS Certificate Manager (ACM) to use with services that are integrated with ACM. Note that <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html">integrated services</a> allow only certificate types and keys they support to be associated with their resources. Further, their support differs depending on whether the certificate is imported into IAM or into ACM. For more information, see the documentation for each service. For more information about importing certificates into ACM, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html">Importing Certificates</a> in the <i>AWS Certificate Manager User Guide</i>. </p> <note> <p>ACM does not provide <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-renewal.html">managed renewal</a> for certificates that you import.</p> </note> <p>Note the following guidelines when importing third party certificates:</p> <ul> <li> <p>You must enter the private key that matches the certificate you are importing.</p> </li> <li> <p>The private key must be unencrypted. You cannot import a private key that is protected by a password or a passphrase.</p> </li> <li> <p>If the certificate you are importing is not self-signed, you must enter its certificate chain.</p> </li> <li> <p>If a certificate chain is included, the issuer must be the subject of one of the certificates in the chain.</p> </li> <li> <p>The certificate, private key, and certificate chain must be PEM-encoded.</p> </li> <li> <p>The current time must be between the <code>Not Before</code> and <code>Not After</code> certificate fields.</p> </li> <li> <p>The <code>Issuer</code> field must not be empty.</p> </li> <li> <p>The OCSP authority URL, if present, must not exceed 1000 characters.</p> </li> <li> <p>To import a new certificate, omit the <code>CertificateArn</code> argument. Include this argument only when you want to replace a previously imported certificate.</p> </li> <li> <p>When you import a certificate by using the CLI, you must specify the certificate, the certificate chain, and the private key by their file names preceded by <code>file://</code>. For example, you can specify a certificate saved in the <code>C:\temp</code> folder as <code>file://C:\temp\certificate_to_import.pem</code>. If you are making an HTTP or HTTPS Query request, include these arguments as BLOBs. </p> </li> <li> <p>When you import a certificate by using an SDK, you must specify the certificate, the certificate chain, and the private key files in the manner required by the programming language you're using. </p> </li> </ul> <p>This operation returns the <a href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Name (ARN)</a> of the imported certificate.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var importCertificate* = Call_ImportCertificate_603132(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ImportCertificate",
    validator: validate_ImportCertificate_603133, base: "/",
    url: url_ImportCertificate_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificates_603147 = ref object of OpenApiRestCall_602466
proc url_ListCertificates_603149(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCertificates_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = query.getOrDefault("NextToken")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "NextToken", valid_603150
  var valid_603151 = query.getOrDefault("MaxItems")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "MaxItems", valid_603151
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
  var valid_603152 = header.getOrDefault("X-Amz-Date")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Date", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Security-Token")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Security-Token", valid_603153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603154 = header.getOrDefault("X-Amz-Target")
  valid_603154 = validateParameter(valid_603154, JString, required = true, default = newJString(
      "CertificateManager.ListCertificates"))
  if valid_603154 != nil:
    section.add "X-Amz-Target", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Content-Sha256", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Signature")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Signature", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Credential")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Credential", valid_603159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603161: Call_ListCertificates_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of certificate ARNs and domain names. You can request that only certificates that match a specific status be listed. You can also filter by specific attributes of the certificate. 
  ## 
  let valid = call_603161.validator(path, query, header, formData, body)
  let scheme = call_603161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603161.url(scheme.get, call_603161.host, call_603161.base,
                         call_603161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603161, url, valid)

proc call*(call_603162: Call_ListCertificates_603147; body: JsonNode;
          NextToken: string = ""; MaxItems: string = ""): Recallable =
  ## listCertificates
  ## Retrieves a list of certificate ARNs and domain names. You can request that only certificates that match a specific status be listed. You can also filter by specific attributes of the certificate. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603163 = newJObject()
  var body_603164 = newJObject()
  add(query_603163, "NextToken", newJString(NextToken))
  if body != nil:
    body_603164 = body
  add(query_603163, "MaxItems", newJString(MaxItems))
  result = call_603162.call(nil, query_603163, nil, nil, body_603164)

var listCertificates* = Call_ListCertificates_603147(name: "listCertificates",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ListCertificates",
    validator: validate_ListCertificates_603148, base: "/",
    url: url_ListCertificates_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForCertificate_603166 = ref object of OpenApiRestCall_602466
proc url_ListTagsForCertificate_603168(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForCertificate_603167(path: JsonNode; query: JsonNode;
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
  var valid_603169 = header.getOrDefault("X-Amz-Date")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Date", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Security-Token")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Security-Token", valid_603170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603171 = header.getOrDefault("X-Amz-Target")
  valid_603171 = validateParameter(valid_603171, JString, required = true, default = newJString(
      "CertificateManager.ListTagsForCertificate"))
  if valid_603171 != nil:
    section.add "X-Amz-Target", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_ListTagsForCertificate_603166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that have been applied to the ACM certificate. Use the certificate's Amazon Resource Name (ARN) to specify the certificate. To add a tag to an ACM certificate, use the <a>AddTagsToCertificate</a> action. To delete a tag, use the <a>RemoveTagsFromCertificate</a> action. 
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_ListTagsForCertificate_603166; body: JsonNode): Recallable =
  ## listTagsForCertificate
  ## Lists the tags that have been applied to the ACM certificate. Use the certificate's Amazon Resource Name (ARN) to specify the certificate. To add a tag to an ACM certificate, use the <a>AddTagsToCertificate</a> action. To delete a tag, use the <a>RemoveTagsFromCertificate</a> action. 
  ##   body: JObject (required)
  var body_603180 = newJObject()
  if body != nil:
    body_603180 = body
  result = call_603179.call(nil, nil, nil, nil, body_603180)

var listTagsForCertificate* = Call_ListTagsForCertificate_603166(
    name: "listTagsForCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ListTagsForCertificate",
    validator: validate_ListTagsForCertificate_603167, base: "/",
    url: url_ListTagsForCertificate_603168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromCertificate_603181 = ref object of OpenApiRestCall_602466
proc url_RemoveTagsFromCertificate_603183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromCertificate_603182(path: JsonNode; query: JsonNode;
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
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603186 = header.getOrDefault("X-Amz-Target")
  valid_603186 = validateParameter(valid_603186, JString, required = true, default = newJString(
      "CertificateManager.RemoveTagsFromCertificate"))
  if valid_603186 != nil:
    section.add "X-Amz-Target", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Content-Sha256", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-SignedHeaders", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Credential")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Credential", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_RemoveTagsFromCertificate_603181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove one or more tags from an ACM certificate. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this function, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. </p> <p>To add tags to a certificate, use the <a>AddTagsToCertificate</a> action. To view all of the tags that have been applied to a specific ACM certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_RemoveTagsFromCertificate_603181; body: JsonNode): Recallable =
  ## removeTagsFromCertificate
  ## <p>Remove one or more tags from an ACM certificate. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this function, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. </p> <p>To add tags to a certificate, use the <a>AddTagsToCertificate</a> action. To view all of the tags that have been applied to a specific ACM certificate, use the <a>ListTagsForCertificate</a> action. </p>
  ##   body: JObject (required)
  var body_603195 = newJObject()
  if body != nil:
    body_603195 = body
  result = call_603194.call(nil, nil, nil, nil, body_603195)

var removeTagsFromCertificate* = Call_RemoveTagsFromCertificate_603181(
    name: "removeTagsFromCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RemoveTagsFromCertificate",
    validator: validate_RemoveTagsFromCertificate_603182, base: "/",
    url: url_RemoveTagsFromCertificate_603183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewCertificate_603196 = ref object of OpenApiRestCall_602466
proc url_RenewCertificate_603198(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RenewCertificate_603197(path: JsonNode; query: JsonNode;
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
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603201 = header.getOrDefault("X-Amz-Target")
  valid_603201 = validateParameter(valid_603201, JString, required = true, default = newJString(
      "CertificateManager.RenewCertificate"))
  if valid_603201 != nil:
    section.add "X-Amz-Target", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_RenewCertificate_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renews an eligable ACM certificate. At this time, only exported private certificates can be renewed with this operation. In order to renew your ACM PCA certificates with ACM, you must first <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaPermissions.html">grant the ACM service principal permission to do so</a>. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/manual-renewal.html">Testing Managed Renewal</a> in the ACM User Guide.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_RenewCertificate_603196; body: JsonNode): Recallable =
  ## renewCertificate
  ## Renews an eligable ACM certificate. At this time, only exported private certificates can be renewed with this operation. In order to renew your ACM PCA certificates with ACM, you must first <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaPermissions.html">grant the ACM service principal permission to do so</a>. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/manual-renewal.html">Testing Managed Renewal</a> in the ACM User Guide.
  ##   body: JObject (required)
  var body_603210 = newJObject()
  if body != nil:
    body_603210 = body
  result = call_603209.call(nil, nil, nil, nil, body_603210)

var renewCertificate* = Call_RenewCertificate_603196(name: "renewCertificate",
    meth: HttpMethod.HttpPost, host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RenewCertificate",
    validator: validate_RenewCertificate_603197, base: "/",
    url: url_RenewCertificate_603198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestCertificate_603211 = ref object of OpenApiRestCall_602466
proc url_RequestCertificate_603213(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RequestCertificate_603212(path: JsonNode; query: JsonNode;
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
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603216 = header.getOrDefault("X-Amz-Target")
  valid_603216 = validateParameter(valid_603216, JString, required = true, default = newJString(
      "CertificateManager.RequestCertificate"))
  if valid_603216 != nil:
    section.add "X-Amz-Target", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Signature", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-SignedHeaders", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Credential")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Credential", valid_603221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_RequestCertificate_603211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests an ACM certificate for use with other AWS services. To request an ACM certificate, you must specify a fully qualified domain name (FQDN) in the <code>DomainName</code> parameter. You can also specify additional FQDNs in the <code>SubjectAlternativeNames</code> parameter. </p> <p>If you are requesting a private certificate, domain validation is not required. If you are requesting a public certificate, each domain name that you specify must be validated to verify that you own or control the domain. You can use <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html">DNS validation</a> or <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-email.html">email validation</a>. We recommend that you use DNS validation. ACM issues public certificates after receiving approval from the domain owner. </p>
  ## 
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603223, url, valid)

proc call*(call_603224: Call_RequestCertificate_603211; body: JsonNode): Recallable =
  ## requestCertificate
  ## <p>Requests an ACM certificate for use with other AWS services. To request an ACM certificate, you must specify a fully qualified domain name (FQDN) in the <code>DomainName</code> parameter. You can also specify additional FQDNs in the <code>SubjectAlternativeNames</code> parameter. </p> <p>If you are requesting a private certificate, domain validation is not required. If you are requesting a public certificate, each domain name that you specify must be validated to verify that you own or control the domain. You can use <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html">DNS validation</a> or <a href="https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-email.html">email validation</a>. We recommend that you use DNS validation. ACM issues public certificates after receiving approval from the domain owner. </p>
  ##   body: JObject (required)
  var body_603225 = newJObject()
  if body != nil:
    body_603225 = body
  result = call_603224.call(nil, nil, nil, nil, body_603225)

var requestCertificate* = Call_RequestCertificate_603211(
    name: "requestCertificate", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.RequestCertificate",
    validator: validate_RequestCertificate_603212, base: "/",
    url: url_RequestCertificate_603213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendValidationEmail_603226 = ref object of OpenApiRestCall_602466
proc url_ResendValidationEmail_603228(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResendValidationEmail_603227(path: JsonNode; query: JsonNode;
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
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603231 = header.getOrDefault("X-Amz-Target")
  valid_603231 = validateParameter(valid_603231, JString, required = true, default = newJString(
      "CertificateManager.ResendValidationEmail"))
  if valid_603231 != nil:
    section.add "X-Amz-Target", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_ResendValidationEmail_603226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the email that requests domain ownership validation. The domain owner or an authorized representative must approve the ACM certificate before it can be issued. The certificate can be approved by clicking a link in the mail to navigate to the Amazon certificate approval website and then clicking <b>I Approve</b>. However, the validation email can be blocked by spam filters. Therefore, if you do not receive the original mail, you can request that the mail be resent within 72 hours of requesting the ACM certificate. If more than 72 hours have elapsed since your original request or since your last attempt to resend validation mail, you must request a new certificate. For more information about setting up your contact email addresses, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/setup-email.html">Configure Email for your Domain</a>. 
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603238, url, valid)

proc call*(call_603239: Call_ResendValidationEmail_603226; body: JsonNode): Recallable =
  ## resendValidationEmail
  ## Resends the email that requests domain ownership validation. The domain owner or an authorized representative must approve the ACM certificate before it can be issued. The certificate can be approved by clicking a link in the mail to navigate to the Amazon certificate approval website and then clicking <b>I Approve</b>. However, the validation email can be blocked by spam filters. Therefore, if you do not receive the original mail, you can request that the mail be resent within 72 hours of requesting the ACM certificate. If more than 72 hours have elapsed since your original request or since your last attempt to resend validation mail, you must request a new certificate. For more information about setting up your contact email addresses, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/setup-email.html">Configure Email for your Domain</a>. 
  ##   body: JObject (required)
  var body_603240 = newJObject()
  if body != nil:
    body_603240 = body
  result = call_603239.call(nil, nil, nil, nil, body_603240)

var resendValidationEmail* = Call_ResendValidationEmail_603226(
    name: "resendValidationEmail", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.ResendValidationEmail",
    validator: validate_ResendValidationEmail_603227, base: "/",
    url: url_ResendValidationEmail_603228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCertificateOptions_603241 = ref object of OpenApiRestCall_602466
proc url_UpdateCertificateOptions_603243(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCertificateOptions_603242(path: JsonNode; query: JsonNode;
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
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603246 = header.getOrDefault("X-Amz-Target")
  valid_603246 = validateParameter(valid_603246, JString, required = true, default = newJString(
      "CertificateManager.UpdateCertificateOptions"))
  if valid_603246 != nil:
    section.add "X-Amz-Target", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Content-Sha256", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-SignedHeaders", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Credential")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Credential", valid_603251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_UpdateCertificateOptions_603241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a certificate. Currently, you can use this function to specify whether to opt in to or out of recording your certificate in a certificate transparency log. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-bestpractices.html#best-practices-transparency"> Opting Out of Certificate Transparency Logging</a>. 
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_UpdateCertificateOptions_603241; body: JsonNode): Recallable =
  ## updateCertificateOptions
  ## Updates a certificate. Currently, you can use this function to specify whether to opt in to or out of recording your certificate in a certificate transparency log. For more information, see <a href="https://docs.aws.amazon.com/acm/latest/userguide/acm-bestpractices.html#best-practices-transparency"> Opting Out of Certificate Transparency Logging</a>. 
  ##   body: JObject (required)
  var body_603255 = newJObject()
  if body != nil:
    body_603255 = body
  result = call_603254.call(nil, nil, nil, nil, body_603255)

var updateCertificateOptions* = Call_UpdateCertificateOptions_603241(
    name: "updateCertificateOptions", meth: HttpMethod.HttpPost,
    host: "acm.amazonaws.com",
    route: "/#X-Amz-Target=CertificateManager.UpdateCertificateOptions",
    validator: validate_UpdateCertificateOptions_603242, base: "/",
    url: url_UpdateCertificateOptions_603243, schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
