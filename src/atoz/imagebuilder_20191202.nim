
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: EC2 Image Builder
## version: 2019-12-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  Amazon Elastic Compute Cloud Image Builder provides a one-stop-shop to automate the image management processes. You configure an automated pipeline that creates images for use on AWS. As software updates become available, Image Builder automatically produces a new image based on a customizable schedule and distributes it to stipulated AWS Regions after running tests on it. With the Image Builder, organizations can capture their internal or industry-specific compliance policies as a vetted template that can be consistently applied to every new image. Built-in integration with AWS Organizations provides customers with a centralized way to enforce image distribution and access policies across their AWS accounts and Regions. Image Builder supports multiple image format AMIs on AWS.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/imagebuilder/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com", "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com",
                           "us-west-2": "imagebuilder.us-west-2.amazonaws.com",
                           "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com", "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com", "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com",
                           "us-east-2": "imagebuilder.us-east-2.amazonaws.com",
                           "us-east-1": "imagebuilder.us-east-1.amazonaws.com", "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com", "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com", "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com",
                           "us-west-1": "imagebuilder.us-west-1.amazonaws.com", "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com", "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com",
                           "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com", "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com", "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com", "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com",
      "us-west-2": "imagebuilder.us-west-2.amazonaws.com",
      "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com",
      "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com",
      "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com",
      "us-east-2": "imagebuilder.us-east-2.amazonaws.com",
      "us-east-1": "imagebuilder.us-east-1.amazonaws.com",
      "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com",
      "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com",
      "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com",
      "us-west-1": "imagebuilder.us-west-1.amazonaws.com",
      "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com",
      "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com",
      "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com",
      "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com",
      "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com",
      "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "imagebuilder"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelImageCreation_605927 = ref object of OpenApiRestCall_605589
proc url_CancelImageCreation_605929(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelImageCreation_605928(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Algorithm")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Algorithm", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-SignedHeaders", valid_606047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_CancelImageCreation_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ## 
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_CancelImageCreation_605927; body: JsonNode): Recallable =
  ## cancelImageCreation
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ##   body: JObject (required)
  var body_606143 = newJObject()
  if body != nil:
    body_606143 = body
  result = call_606142.call(nil, nil, nil, nil, body_606143)

var cancelImageCreation* = Call_CancelImageCreation_605927(
    name: "cancelImageCreation", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CancelImageCreation",
    validator: validate_CancelImageCreation_605928, base: "/",
    url: url_CancelImageCreation_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_606182 = ref object of OpenApiRestCall_605589
proc url_CreateComponent_606184(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_606183(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606185 = header.getOrDefault("X-Amz-Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Signature", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Content-Sha256", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Date")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Date", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Credential")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Credential", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Security-Token")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Security-Token", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Algorithm")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Algorithm", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_CreateComponent_606182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_CreateComponent_606182; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ##   body: JObject (required)
  var body_606195 = newJObject()
  if body != nil:
    body_606195 = body
  result = call_606194.call(nil, nil, nil, nil, body_606195)

var createComponent* = Call_CreateComponent_606182(name: "createComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateComponent", validator: validate_CreateComponent_606183,
    base: "/", url: url_CreateComponent_606184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionConfiguration_606196 = ref object of OpenApiRestCall_605589
proc url_CreateDistributionConfiguration_606198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionConfiguration_606197(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606199 = header.getOrDefault("X-Amz-Signature")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Signature", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Content-Sha256", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Date")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Date", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Credential")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Credential", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Security-Token")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Security-Token", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Algorithm")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Algorithm", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-SignedHeaders", valid_606205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606207: Call_CreateDistributionConfiguration_606196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_606207.validator(path, query, header, formData, body)
  let scheme = call_606207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606207.url(scheme.get, call_606207.host, call_606207.base,
                         call_606207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606207, url, valid)

proc call*(call_606208: Call_CreateDistributionConfiguration_606196; body: JsonNode): Recallable =
  ## createDistributionConfiguration
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_606209 = newJObject()
  if body != nil:
    body_606209 = body
  result = call_606208.call(nil, nil, nil, nil, body_606209)

var createDistributionConfiguration* = Call_CreateDistributionConfiguration_606196(
    name: "createDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateDistributionConfiguration",
    validator: validate_CreateDistributionConfiguration_606197, base: "/",
    url: url_CreateDistributionConfiguration_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImage_606210 = ref object of OpenApiRestCall_605589
proc url_CreateImage_606212(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImage_606211(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606213 = header.getOrDefault("X-Amz-Signature")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Signature", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Content-Sha256", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Date")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Date", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Credential")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Credential", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Security-Token")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Security-Token", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Algorithm")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Algorithm", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-SignedHeaders", valid_606219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606221: Call_CreateImage_606210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  let valid = call_606221.validator(path, query, header, formData, body)
  let scheme = call_606221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606221.url(scheme.get, call_606221.host, call_606221.base,
                         call_606221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606221, url, valid)

proc call*(call_606222: Call_CreateImage_606210; body: JsonNode): Recallable =
  ## createImage
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ##   body: JObject (required)
  var body_606223 = newJObject()
  if body != nil:
    body_606223 = body
  result = call_606222.call(nil, nil, nil, nil, body_606223)

var createImage* = Call_CreateImage_606210(name: "createImage",
                                        meth: HttpMethod.HttpPut,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/CreateImage",
                                        validator: validate_CreateImage_606211,
                                        base: "/", url: url_CreateImage_606212,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImagePipeline_606224 = ref object of OpenApiRestCall_605589
proc url_CreateImagePipeline_606226(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImagePipeline_606225(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606227 = header.getOrDefault("X-Amz-Signature")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Signature", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Content-Sha256", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Date")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Date", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Credential")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Credential", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Security-Token")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Security-Token", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Algorithm")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Algorithm", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-SignedHeaders", valid_606233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606235: Call_CreateImagePipeline_606224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_606235.validator(path, query, header, formData, body)
  let scheme = call_606235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606235.url(scheme.get, call_606235.host, call_606235.base,
                         call_606235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606235, url, valid)

proc call*(call_606236: Call_CreateImagePipeline_606224; body: JsonNode): Recallable =
  ## createImagePipeline
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_606237 = newJObject()
  if body != nil:
    body_606237 = body
  result = call_606236.call(nil, nil, nil, nil, body_606237)

var createImagePipeline* = Call_CreateImagePipeline_606224(
    name: "createImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImagePipeline",
    validator: validate_CreateImagePipeline_606225, base: "/",
    url: url_CreateImagePipeline_606226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageRecipe_606238 = ref object of OpenApiRestCall_605589
proc url_CreateImageRecipe_606240(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImageRecipe_606239(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606241 = header.getOrDefault("X-Amz-Signature")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Signature", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Content-Sha256", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Date")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Date", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Credential")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Credential", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Security-Token")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Security-Token", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Algorithm")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Algorithm", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-SignedHeaders", valid_606247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606249: Call_CreateImageRecipe_606238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ## 
  let valid = call_606249.validator(path, query, header, formData, body)
  let scheme = call_606249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606249.url(scheme.get, call_606249.host, call_606249.base,
                         call_606249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606249, url, valid)

proc call*(call_606250: Call_CreateImageRecipe_606238; body: JsonNode): Recallable =
  ## createImageRecipe
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ##   body: JObject (required)
  var body_606251 = newJObject()
  if body != nil:
    body_606251 = body
  result = call_606250.call(nil, nil, nil, nil, body_606251)

var createImageRecipe* = Call_CreateImageRecipe_606238(name: "createImageRecipe",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateImageRecipe", validator: validate_CreateImageRecipe_606239,
    base: "/", url: url_CreateImageRecipe_606240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInfrastructureConfiguration_606252 = ref object of OpenApiRestCall_605589
proc url_CreateInfrastructureConfiguration_606254(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInfrastructureConfiguration_606253(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606255 = header.getOrDefault("X-Amz-Signature")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Signature", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Content-Sha256", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Date")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Date", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Credential")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Credential", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Security-Token")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Security-Token", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Algorithm")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Algorithm", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-SignedHeaders", valid_606261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606263: Call_CreateInfrastructureConfiguration_606252;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_606263.validator(path, query, header, formData, body)
  let scheme = call_606263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606263.url(scheme.get, call_606263.host, call_606263.base,
                         call_606263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606263, url, valid)

proc call*(call_606264: Call_CreateInfrastructureConfiguration_606252;
          body: JsonNode): Recallable =
  ## createInfrastructureConfiguration
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_606265 = newJObject()
  if body != nil:
    body_606265 = body
  result = call_606264.call(nil, nil, nil, nil, body_606265)

var createInfrastructureConfiguration* = Call_CreateInfrastructureConfiguration_606252(
    name: "createInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateInfrastructureConfiguration",
    validator: validate_CreateInfrastructureConfiguration_606253, base: "/",
    url: url_CreateInfrastructureConfiguration_606254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_606266 = ref object of OpenApiRestCall_605589
proc url_DeleteComponent_606268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_606267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Deletes a component build version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_606269 = query.getOrDefault("componentBuildVersionArn")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "componentBuildVersionArn", valid_606269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606270 = header.getOrDefault("X-Amz-Signature")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Signature", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Content-Sha256", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Date")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Date", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Credential")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Credential", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Security-Token")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Security-Token", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Algorithm")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Algorithm", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-SignedHeaders", valid_606276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606277: Call_DeleteComponent_606266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a component build version. 
  ## 
  let valid = call_606277.validator(path, query, header, formData, body)
  let scheme = call_606277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606277.url(scheme.get, call_606277.host, call_606277.base,
                         call_606277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606277, url, valid)

proc call*(call_606278: Call_DeleteComponent_606266;
          componentBuildVersionArn: string): Recallable =
  ## deleteComponent
  ##  Deletes a component build version. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  var query_606279 = newJObject()
  add(query_606279, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_606278.call(nil, query_606279, nil, nil, nil)

var deleteComponent* = Call_DeleteComponent_606266(name: "deleteComponent",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteComponent#componentBuildVersionArn",
    validator: validate_DeleteComponent_606267, base: "/", url: url_DeleteComponent_606268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistributionConfiguration_606281 = ref object of OpenApiRestCall_605589
proc url_DeleteDistributionConfiguration_606283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDistributionConfiguration_606282(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_606284 = query.getOrDefault("distributionConfigurationArn")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = nil)
  if valid_606284 != nil:
    section.add "distributionConfigurationArn", valid_606284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606285 = header.getOrDefault("X-Amz-Signature")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Signature", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Content-Sha256", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Date")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Date", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Credential")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Credential", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Security-Token")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Security-Token", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Algorithm")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Algorithm", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-SignedHeaders", valid_606291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_DeleteDistributionConfiguration_606281;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes a distribution configuration. 
  ## 
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_DeleteDistributionConfiguration_606281;
          distributionConfigurationArn: string): Recallable =
  ## deleteDistributionConfiguration
  ##  Deletes a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  var query_606294 = newJObject()
  add(query_606294, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_606293.call(nil, query_606294, nil, nil, nil)

var deleteDistributionConfiguration* = Call_DeleteDistributionConfiguration_606281(
    name: "deleteDistributionConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteDistributionConfiguration#distributionConfigurationArn",
    validator: validate_DeleteDistributionConfiguration_606282, base: "/",
    url: url_DeleteDistributionConfiguration_606283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_606295 = ref object of OpenApiRestCall_605589
proc url_DeleteImage_606297(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImage_606296(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_606298 = query.getOrDefault("imageBuildVersionArn")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = nil)
  if valid_606298 != nil:
    section.add "imageBuildVersionArn", valid_606298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606306: Call_DeleteImage_606295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image. 
  ## 
  let valid = call_606306.validator(path, query, header, formData, body)
  let scheme = call_606306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606306.url(scheme.get, call_606306.host, call_606306.base,
                         call_606306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606306, url, valid)

proc call*(call_606307: Call_DeleteImage_606295; imageBuildVersionArn: string): Recallable =
  ## deleteImage
  ##  Deletes an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  var query_606308 = newJObject()
  add(query_606308, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_606307.call(nil, query_606308, nil, nil, nil)

var deleteImage* = Call_DeleteImage_606295(name: "deleteImage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "imagebuilder.amazonaws.com", route: "/DeleteImage#imageBuildVersionArn",
                                        validator: validate_DeleteImage_606296,
                                        base: "/", url: url_DeleteImage_606297,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePipeline_606309 = ref object of OpenApiRestCall_605589
proc url_DeleteImagePipeline_606311(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImagePipeline_606310(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Deletes an image pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imagePipelineArn` field"
  var valid_606312 = query.getOrDefault("imagePipelineArn")
  valid_606312 = validateParameter(valid_606312, JString, required = true,
                                 default = nil)
  if valid_606312 != nil:
    section.add "imagePipelineArn", valid_606312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606313 = header.getOrDefault("X-Amz-Signature")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Signature", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Content-Sha256", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Date")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Date", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Credential")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Credential", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Security-Token")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Security-Token", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Algorithm")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Algorithm", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-SignedHeaders", valid_606319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_DeleteImagePipeline_606309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image pipeline. 
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_DeleteImagePipeline_606309; imagePipelineArn: string): Recallable =
  ## deleteImagePipeline
  ##  Deletes an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  var query_606322 = newJObject()
  add(query_606322, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_606321.call(nil, query_606322, nil, nil, nil)

var deleteImagePipeline* = Call_DeleteImagePipeline_606309(
    name: "deleteImagePipeline", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImagePipeline#imagePipelineArn",
    validator: validate_DeleteImagePipeline_606310, base: "/",
    url: url_DeleteImagePipeline_606311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageRecipe_606323 = ref object of OpenApiRestCall_605589
proc url_DeleteImageRecipe_606325(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImageRecipe_606324(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Deletes an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_606326 = query.getOrDefault("imageRecipeArn")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = nil)
  if valid_606326 != nil:
    section.add "imageRecipeArn", valid_606326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DeleteImageRecipe_606323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image recipe. 
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DeleteImageRecipe_606323; imageRecipeArn: string): Recallable =
  ## deleteImageRecipe
  ##  Deletes an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  var query_606336 = newJObject()
  add(query_606336, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_606335.call(nil, query_606336, nil, nil, nil)

var deleteImageRecipe* = Call_DeleteImageRecipe_606323(name: "deleteImageRecipe",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteImageRecipe#imageRecipeArn",
    validator: validate_DeleteImageRecipe_606324, base: "/",
    url: url_DeleteImageRecipe_606325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInfrastructureConfiguration_606337 = ref object of OpenApiRestCall_605589
proc url_DeleteInfrastructureConfiguration_606339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInfrastructureConfiguration_606338(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes an infrastructure configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_606340 = query.getOrDefault("infrastructureConfigurationArn")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = nil)
  if valid_606340 != nil:
    section.add "infrastructureConfigurationArn", valid_606340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606348: Call_DeleteInfrastructureConfiguration_606337;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes an infrastructure configuration. 
  ## 
  let valid = call_606348.validator(path, query, header, formData, body)
  let scheme = call_606348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606348.url(scheme.get, call_606348.host, call_606348.base,
                         call_606348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606348, url, valid)

proc call*(call_606349: Call_DeleteInfrastructureConfiguration_606337;
          infrastructureConfigurationArn: string): Recallable =
  ## deleteInfrastructureConfiguration
  ##  Deletes an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  var query_606350 = newJObject()
  add(query_606350, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_606349.call(nil, query_606350, nil, nil, nil)

var deleteInfrastructureConfiguration* = Call_DeleteInfrastructureConfiguration_606337(
    name: "deleteInfrastructureConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_DeleteInfrastructureConfiguration_606338, base: "/",
    url: url_DeleteInfrastructureConfiguration_606339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponent_606351 = ref object of OpenApiRestCall_605589
proc url_GetComponent_606353(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponent_606352(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets a component object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you wish to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_606354 = query.getOrDefault("componentBuildVersionArn")
  valid_606354 = validateParameter(valid_606354, JString, required = true,
                                 default = nil)
  if valid_606354 != nil:
    section.add "componentBuildVersionArn", valid_606354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606355 = header.getOrDefault("X-Amz-Signature")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Signature", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Content-Sha256", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Date")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Date", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Credential")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Credential", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Security-Token")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Security-Token", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Algorithm")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Algorithm", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-SignedHeaders", valid_606361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606362: Call_GetComponent_606351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component object. 
  ## 
  let valid = call_606362.validator(path, query, header, formData, body)
  let scheme = call_606362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606362.url(scheme.get, call_606362.host, call_606362.base,
                         call_606362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606362, url, valid)

proc call*(call_606363: Call_GetComponent_606351; componentBuildVersionArn: string): Recallable =
  ## getComponent
  ##  Gets a component object. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you wish to retrieve. 
  var query_606364 = newJObject()
  add(query_606364, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_606363.call(nil, query_606364, nil, nil, nil)

var getComponent* = Call_GetComponent_606351(name: "getComponent",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetComponent#componentBuildVersionArn",
    validator: validate_GetComponent_606352, base: "/", url: url_GetComponent_606353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponentPolicy_606365 = ref object of OpenApiRestCall_605589
proc url_GetComponentPolicy_606367(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponentPolicy_606366(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Gets a component policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentArn: JString (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you wish to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `componentArn` field"
  var valid_606368 = query.getOrDefault("componentArn")
  valid_606368 = validateParameter(valid_606368, JString, required = true,
                                 default = nil)
  if valid_606368 != nil:
    section.add "componentArn", valid_606368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606369 = header.getOrDefault("X-Amz-Signature")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Signature", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Content-Sha256", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Date")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Date", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Credential")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Credential", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Security-Token")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Security-Token", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Algorithm")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Algorithm", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-SignedHeaders", valid_606375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606376: Call_GetComponentPolicy_606365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component policy. 
  ## 
  let valid = call_606376.validator(path, query, header, formData, body)
  let scheme = call_606376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606376.url(scheme.get, call_606376.host, call_606376.base,
                         call_606376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606376, url, valid)

proc call*(call_606377: Call_GetComponentPolicy_606365; componentArn: string): Recallable =
  ## getComponentPolicy
  ##  Gets a component policy. 
  ##   componentArn: string (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you wish to retrieve. 
  var query_606378 = newJObject()
  add(query_606378, "componentArn", newJString(componentArn))
  result = call_606377.call(nil, query_606378, nil, nil, nil)

var getComponentPolicy* = Call_GetComponentPolicy_606365(
    name: "getComponentPolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/GetComponentPolicy#componentArn",
    validator: validate_GetComponentPolicy_606366, base: "/",
    url: url_GetComponentPolicy_606367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfiguration_606379 = ref object of OpenApiRestCall_605589
proc url_GetDistributionConfiguration_606381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDistributionConfiguration_606380(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets a distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you wish to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_606382 = query.getOrDefault("distributionConfigurationArn")
  valid_606382 = validateParameter(valid_606382, JString, required = true,
                                 default = nil)
  if valid_606382 != nil:
    section.add "distributionConfigurationArn", valid_606382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606383 = header.getOrDefault("X-Amz-Signature")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Signature", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Content-Sha256", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Date")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Date", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Credential")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Credential", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Security-Token")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Security-Token", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Algorithm")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Algorithm", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-SignedHeaders", valid_606389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606390: Call_GetDistributionConfiguration_606379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a distribution configuration. 
  ## 
  let valid = call_606390.validator(path, query, header, formData, body)
  let scheme = call_606390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606390.url(scheme.get, call_606390.host, call_606390.base,
                         call_606390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606390, url, valid)

proc call*(call_606391: Call_GetDistributionConfiguration_606379;
          distributionConfigurationArn: string): Recallable =
  ## getDistributionConfiguration
  ##  Gets a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you wish to retrieve. 
  var query_606392 = newJObject()
  add(query_606392, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_606391.call(nil, query_606392, nil, nil, nil)

var getDistributionConfiguration* = Call_GetDistributionConfiguration_606379(
    name: "getDistributionConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetDistributionConfiguration#distributionConfigurationArn",
    validator: validate_GetDistributionConfiguration_606380, base: "/",
    url: url_GetDistributionConfiguration_606381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImage_606393 = ref object of OpenApiRestCall_605589
proc url_GetImage_606395(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImage_606394(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you wish to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_606396 = query.getOrDefault("imageBuildVersionArn")
  valid_606396 = validateParameter(valid_606396, JString, required = true,
                                 default = nil)
  if valid_606396 != nil:
    section.add "imageBuildVersionArn", valid_606396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606397 = header.getOrDefault("X-Amz-Signature")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Signature", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Content-Sha256", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Date")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Date", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Credential")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Credential", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Security-Token")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Security-Token", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Algorithm")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Algorithm", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-SignedHeaders", valid_606403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606404: Call_GetImage_606393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image. 
  ## 
  let valid = call_606404.validator(path, query, header, formData, body)
  let scheme = call_606404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606404.url(scheme.get, call_606404.host, call_606404.base,
                         call_606404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606404, url, valid)

proc call*(call_606405: Call_GetImage_606393; imageBuildVersionArn: string): Recallable =
  ## getImage
  ##  Gets an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you wish to retrieve. 
  var query_606406 = newJObject()
  add(query_606406, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_606405.call(nil, query_606406, nil, nil, nil)

var getImage* = Call_GetImage_606393(name: "getImage", meth: HttpMethod.HttpGet,
                                  host: "imagebuilder.amazonaws.com",
                                  route: "/GetImage#imageBuildVersionArn",
                                  validator: validate_GetImage_606394, base: "/",
                                  url: url_GetImage_606395,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePipeline_606407 = ref object of OpenApiRestCall_605589
proc url_GetImagePipeline_606409(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePipeline_606408(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Gets an image pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you wish to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imagePipelineArn` field"
  var valid_606410 = query.getOrDefault("imagePipelineArn")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "imagePipelineArn", valid_606410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Security-Token")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Security-Token", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Algorithm")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Algorithm", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-SignedHeaders", valid_606417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_GetImagePipeline_606407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image pipeline. 
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_GetImagePipeline_606407; imagePipelineArn: string): Recallable =
  ## getImagePipeline
  ##  Gets an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you wish to retrieve. 
  var query_606420 = newJObject()
  add(query_606420, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_606419.call(nil, query_606420, nil, nil, nil)

var getImagePipeline* = Call_GetImagePipeline_606407(name: "getImagePipeline",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePipeline#imagePipelineArn",
    validator: validate_GetImagePipeline_606408, base: "/",
    url: url_GetImagePipeline_606409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePolicy_606421 = ref object of OpenApiRestCall_605589
proc url_GetImagePolicy_606423(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePolicy_606422(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Gets an image policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageArn: JString (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you wish to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageArn` field"
  var valid_606424 = query.getOrDefault("imageArn")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "imageArn", valid_606424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606432: Call_GetImagePolicy_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image policy. 
  ## 
  let valid = call_606432.validator(path, query, header, formData, body)
  let scheme = call_606432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606432.url(scheme.get, call_606432.host, call_606432.base,
                         call_606432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606432, url, valid)

proc call*(call_606433: Call_GetImagePolicy_606421; imageArn: string): Recallable =
  ## getImagePolicy
  ##  Gets an image policy. 
  ##   imageArn: string (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you wish to retrieve. 
  var query_606434 = newJObject()
  add(query_606434, "imageArn", newJString(imageArn))
  result = call_606433.call(nil, query_606434, nil, nil, nil)

var getImagePolicy* = Call_GetImagePolicy_606421(name: "getImagePolicy",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePolicy#imageArn", validator: validate_GetImagePolicy_606422,
    base: "/", url: url_GetImagePolicy_606423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipe_606435 = ref object of OpenApiRestCall_605589
proc url_GetImageRecipe_606437(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipe_606436(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Gets an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you wish to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_606438 = query.getOrDefault("imageRecipeArn")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "imageRecipeArn", valid_606438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606439 = header.getOrDefault("X-Amz-Signature")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Signature", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Content-Sha256", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Date")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Date", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Credential")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Credential", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Security-Token")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Security-Token", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Algorithm")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Algorithm", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-SignedHeaders", valid_606445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_GetImageRecipe_606435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe. 
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_GetImageRecipe_606435; imageRecipeArn: string): Recallable =
  ## getImageRecipe
  ##  Gets an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you wish to retrieve. 
  var query_606448 = newJObject()
  add(query_606448, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_606447.call(nil, query_606448, nil, nil, nil)

var getImageRecipe* = Call_GetImageRecipe_606435(name: "getImageRecipe",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipe#imageRecipeArn", validator: validate_GetImageRecipe_606436,
    base: "/", url: url_GetImageRecipe_606437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipePolicy_606449 = ref object of OpenApiRestCall_605589
proc url_GetImageRecipePolicy_606451(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipePolicy_606450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets an image recipe policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you wish to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_606452 = query.getOrDefault("imageRecipeArn")
  valid_606452 = validateParameter(valid_606452, JString, required = true,
                                 default = nil)
  if valid_606452 != nil:
    section.add "imageRecipeArn", valid_606452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606453 = header.getOrDefault("X-Amz-Signature")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Signature", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Content-Sha256", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Date")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Date", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Credential")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Credential", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Security-Token")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Security-Token", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Algorithm")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Algorithm", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-SignedHeaders", valid_606459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606460: Call_GetImageRecipePolicy_606449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe policy. 
  ## 
  let valid = call_606460.validator(path, query, header, formData, body)
  let scheme = call_606460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606460.url(scheme.get, call_606460.host, call_606460.base,
                         call_606460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606460, url, valid)

proc call*(call_606461: Call_GetImageRecipePolicy_606449; imageRecipeArn: string): Recallable =
  ## getImageRecipePolicy
  ##  Gets an image recipe policy. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you wish to retrieve. 
  var query_606462 = newJObject()
  add(query_606462, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_606461.call(nil, query_606462, nil, nil, nil)

var getImageRecipePolicy* = Call_GetImageRecipePolicy_606449(
    name: "getImageRecipePolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipePolicy#imageRecipeArn",
    validator: validate_GetImageRecipePolicy_606450, base: "/",
    url: url_GetImageRecipePolicy_606451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInfrastructureConfiguration_606463 = ref object of OpenApiRestCall_605589
proc url_GetInfrastructureConfiguration_606465(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInfrastructureConfiguration_606464(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets a infrastructure configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration that you wish to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_606466 = query.getOrDefault("infrastructureConfigurationArn")
  valid_606466 = validateParameter(valid_606466, JString, required = true,
                                 default = nil)
  if valid_606466 != nil:
    section.add "infrastructureConfigurationArn", valid_606466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606467 = header.getOrDefault("X-Amz-Signature")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Signature", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Content-Sha256", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Date")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Date", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Credential")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Credential", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Security-Token")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Security-Token", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Algorithm")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Algorithm", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-SignedHeaders", valid_606473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606474: Call_GetInfrastructureConfiguration_606463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a infrastructure configuration. 
  ## 
  let valid = call_606474.validator(path, query, header, formData, body)
  let scheme = call_606474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606474.url(scheme.get, call_606474.host, call_606474.base,
                         call_606474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606474, url, valid)

proc call*(call_606475: Call_GetInfrastructureConfiguration_606463;
          infrastructureConfigurationArn: string): Recallable =
  ## getInfrastructureConfiguration
  ##  Gets a infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration that you wish to retrieve. 
  var query_606476 = newJObject()
  add(query_606476, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_606475.call(nil, query_606476, nil, nil, nil)

var getInfrastructureConfiguration* = Call_GetInfrastructureConfiguration_606463(
    name: "getInfrastructureConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_GetInfrastructureConfiguration_606464, base: "/",
    url: url_GetInfrastructureConfiguration_606465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportComponent_606477 = ref object of OpenApiRestCall_605589
proc url_ImportComponent_606479(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportComponent_606478(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Imports a component and transforms its data into a component document. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606480 = header.getOrDefault("X-Amz-Signature")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Signature", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Content-Sha256", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Date")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Date", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Credential")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Credential", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Security-Token")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Security-Token", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Algorithm")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Algorithm", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-SignedHeaders", valid_606486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606488: Call_ImportComponent_606477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports a component and transforms its data into a component document. 
  ## 
  let valid = call_606488.validator(path, query, header, formData, body)
  let scheme = call_606488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606488.url(scheme.get, call_606488.host, call_606488.base,
                         call_606488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606488, url, valid)

proc call*(call_606489: Call_ImportComponent_606477; body: JsonNode): Recallable =
  ## importComponent
  ##  Imports a component and transforms its data into a component document. 
  ##   body: JObject (required)
  var body_606490 = newJObject()
  if body != nil:
    body_606490 = body
  result = call_606489.call(nil, nil, nil, nil, body_606490)

var importComponent* = Call_ImportComponent_606477(name: "importComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/ImportComponent", validator: validate_ImportComponent_606478,
    base: "/", url: url_ImportComponent_606479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponentBuildVersions_606491 = ref object of OpenApiRestCall_605589
proc url_ListComponentBuildVersions_606493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponentBuildVersions_606492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606494 = query.getOrDefault("nextToken")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "nextToken", valid_606494
  var valid_606495 = query.getOrDefault("maxResults")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "maxResults", valid_606495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606496 = header.getOrDefault("X-Amz-Signature")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Signature", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Content-Sha256", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Date")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Date", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Credential")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Credential", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Security-Token")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Security-Token", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Algorithm")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Algorithm", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-SignedHeaders", valid_606502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606504: Call_ListComponentBuildVersions_606491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_606504.validator(path, query, header, formData, body)
  let scheme = call_606504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606504.url(scheme.get, call_606504.host, call_606504.base,
                         call_606504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606504, url, valid)

proc call*(call_606505: Call_ListComponentBuildVersions_606491; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponentBuildVersions
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606506 = newJObject()
  var body_606507 = newJObject()
  add(query_606506, "nextToken", newJString(nextToken))
  if body != nil:
    body_606507 = body
  add(query_606506, "maxResults", newJString(maxResults))
  result = call_606505.call(nil, query_606506, nil, nil, body_606507)

var listComponentBuildVersions* = Call_ListComponentBuildVersions_606491(
    name: "listComponentBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListComponentBuildVersions",
    validator: validate_ListComponentBuildVersions_606492, base: "/",
    url: url_ListComponentBuildVersions_606493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_606508 = ref object of OpenApiRestCall_605589
proc url_ListComponents_606510(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_606509(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606511 = query.getOrDefault("nextToken")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "nextToken", valid_606511
  var valid_606512 = query.getOrDefault("maxResults")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "maxResults", valid_606512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606513 = header.getOrDefault("X-Amz-Signature")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Signature", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Content-Sha256", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Date")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Date", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Credential")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Credential", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Security-Token")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Security-Token", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Algorithm")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Algorithm", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-SignedHeaders", valid_606519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606521: Call_ListComponents_606508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_606521.validator(path, query, header, formData, body)
  let scheme = call_606521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606521.url(scheme.get, call_606521.host, call_606521.base,
                         call_606521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606521, url, valid)

proc call*(call_606522: Call_ListComponents_606508; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponents
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606523 = newJObject()
  var body_606524 = newJObject()
  add(query_606523, "nextToken", newJString(nextToken))
  if body != nil:
    body_606524 = body
  add(query_606523, "maxResults", newJString(maxResults))
  result = call_606522.call(nil, query_606523, nil, nil, body_606524)

var listComponents* = Call_ListComponents_606508(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListComponents", validator: validate_ListComponents_606509, base: "/",
    url: url_ListComponents_606510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionConfigurations_606525 = ref object of OpenApiRestCall_605589
proc url_ListDistributionConfigurations_606527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributionConfigurations_606526(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of distribution configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606528 = query.getOrDefault("nextToken")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "nextToken", valid_606528
  var valid_606529 = query.getOrDefault("maxResults")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "maxResults", valid_606529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_ListDistributionConfigurations_606525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_ListDistributionConfigurations_606525; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDistributionConfigurations
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606540 = newJObject()
  var body_606541 = newJObject()
  add(query_606540, "nextToken", newJString(nextToken))
  if body != nil:
    body_606541 = body
  add(query_606540, "maxResults", newJString(maxResults))
  result = call_606539.call(nil, query_606540, nil, nil, body_606541)

var listDistributionConfigurations* = Call_ListDistributionConfigurations_606525(
    name: "listDistributionConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListDistributionConfigurations",
    validator: validate_ListDistributionConfigurations_606526, base: "/",
    url: url_ListDistributionConfigurations_606527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageBuildVersions_606542 = ref object of OpenApiRestCall_605589
proc url_ListImageBuildVersions_606544(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageBuildVersions_606543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of distribution configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606545 = query.getOrDefault("nextToken")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "nextToken", valid_606545
  var valid_606546 = query.getOrDefault("maxResults")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "maxResults", valid_606546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Security-Token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Security-Token", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Algorithm")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Algorithm", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-SignedHeaders", valid_606553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606555: Call_ListImageBuildVersions_606542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_ListImageBuildVersions_606542; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageBuildVersions
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606557 = newJObject()
  var body_606558 = newJObject()
  add(query_606557, "nextToken", newJString(nextToken))
  if body != nil:
    body_606558 = body
  add(query_606557, "maxResults", newJString(maxResults))
  result = call_606556.call(nil, query_606557, nil, nil, body_606558)

var listImageBuildVersions* = Call_ListImageBuildVersions_606542(
    name: "listImageBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageBuildVersions",
    validator: validate_ListImageBuildVersions_606543, base: "/",
    url: url_ListImageBuildVersions_606544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelineImages_606559 = ref object of OpenApiRestCall_605589
proc url_ListImagePipelineImages_606561(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelineImages_606560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606562 = query.getOrDefault("nextToken")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "nextToken", valid_606562
  var valid_606563 = query.getOrDefault("maxResults")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "maxResults", valid_606563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606564 = header.getOrDefault("X-Amz-Signature")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Signature", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Content-Sha256", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Date")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Date", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Credential")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Credential", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Security-Token")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Security-Token", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Algorithm")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Algorithm", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-SignedHeaders", valid_606570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606572: Call_ListImagePipelineImages_606559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  let valid = call_606572.validator(path, query, header, formData, body)
  let scheme = call_606572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606572.url(scheme.get, call_606572.host, call_606572.base,
                         call_606572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606572, url, valid)

proc call*(call_606573: Call_ListImagePipelineImages_606559; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelineImages
  ##  Returns a list of images created by the specified pipeline. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606574 = newJObject()
  var body_606575 = newJObject()
  add(query_606574, "nextToken", newJString(nextToken))
  if body != nil:
    body_606575 = body
  add(query_606574, "maxResults", newJString(maxResults))
  result = call_606573.call(nil, query_606574, nil, nil, body_606575)

var listImagePipelineImages* = Call_ListImagePipelineImages_606559(
    name: "listImagePipelineImages", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelineImages",
    validator: validate_ListImagePipelineImages_606560, base: "/",
    url: url_ListImagePipelineImages_606561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelines_606576 = ref object of OpenApiRestCall_605589
proc url_ListImagePipelines_606578(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelines_606577(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of image pipelines. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606579 = query.getOrDefault("nextToken")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "nextToken", valid_606579
  var valid_606580 = query.getOrDefault("maxResults")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "maxResults", valid_606580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_ListImagePipelines_606576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of image pipelines. 
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_ListImagePipelines_606576; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelines
  ## Returns a list of image pipelines. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606591 = newJObject()
  var body_606592 = newJObject()
  add(query_606591, "nextToken", newJString(nextToken))
  if body != nil:
    body_606592 = body
  add(query_606591, "maxResults", newJString(maxResults))
  result = call_606590.call(nil, query_606591, nil, nil, body_606592)

var listImagePipelines* = Call_ListImagePipelines_606576(
    name: "listImagePipelines", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelines",
    validator: validate_ListImagePipelines_606577, base: "/",
    url: url_ListImagePipelines_606578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageRecipes_606593 = ref object of OpenApiRestCall_605589
proc url_ListImageRecipes_606595(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageRecipes_606594(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Returns a list of image recipes. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606596 = query.getOrDefault("nextToken")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "nextToken", valid_606596
  var valid_606597 = query.getOrDefault("maxResults")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "maxResults", valid_606597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606598 = header.getOrDefault("X-Amz-Signature")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Signature", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Content-Sha256", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Date")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Date", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Credential")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Credential", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Security-Token")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Security-Token", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Algorithm")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Algorithm", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-SignedHeaders", valid_606604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606606: Call_ListImageRecipes_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of image recipes. 
  ## 
  let valid = call_606606.validator(path, query, header, formData, body)
  let scheme = call_606606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606606.url(scheme.get, call_606606.host, call_606606.base,
                         call_606606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606606, url, valid)

proc call*(call_606607: Call_ListImageRecipes_606593; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageRecipes
  ##  Returns a list of image recipes. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606608 = newJObject()
  var body_606609 = newJObject()
  add(query_606608, "nextToken", newJString(nextToken))
  if body != nil:
    body_606609 = body
  add(query_606608, "maxResults", newJString(maxResults))
  result = call_606607.call(nil, query_606608, nil, nil, body_606609)

var listImageRecipes* = Call_ListImageRecipes_606593(name: "listImageRecipes",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListImageRecipes", validator: validate_ListImageRecipes_606594,
    base: "/", url: url_ListImageRecipes_606595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_606610 = ref object of OpenApiRestCall_605589
proc url_ListImages_606612(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImages_606611(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606613 = query.getOrDefault("nextToken")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "nextToken", valid_606613
  var valid_606614 = query.getOrDefault("maxResults")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "maxResults", valid_606614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606615 = header.getOrDefault("X-Amz-Signature")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Signature", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Content-Sha256", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Date")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Date", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Credential")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Credential", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Security-Token")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Security-Token", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Algorithm")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Algorithm", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-SignedHeaders", valid_606621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606623: Call_ListImages_606610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  let valid = call_606623.validator(path, query, header, formData, body)
  let scheme = call_606623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606623.url(scheme.get, call_606623.host, call_606623.base,
                         call_606623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606623, url, valid)

proc call*(call_606624: Call_ListImages_606610; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ##  Returns the list of image build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606625 = newJObject()
  var body_606626 = newJObject()
  add(query_606625, "nextToken", newJString(nextToken))
  if body != nil:
    body_606626 = body
  add(query_606625, "maxResults", newJString(maxResults))
  result = call_606624.call(nil, query_606625, nil, nil, body_606626)

var listImages* = Call_ListImages_606610(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "imagebuilder.amazonaws.com",
                                      route: "/ListImages",
                                      validator: validate_ListImages_606611,
                                      base: "/", url: url_ListImages_606612,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInfrastructureConfigurations_606627 = ref object of OpenApiRestCall_605589
proc url_ListInfrastructureConfigurations_606629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInfrastructureConfigurations_606628(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of infrastructure configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606630 = query.getOrDefault("nextToken")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "nextToken", valid_606630
  var valid_606631 = query.getOrDefault("maxResults")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "maxResults", valid_606631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606632 = header.getOrDefault("X-Amz-Signature")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Signature", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Content-Sha256", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Date")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Date", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Credential")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Credential", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Security-Token")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Security-Token", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Algorithm")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Algorithm", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-SignedHeaders", valid_606638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606640: Call_ListInfrastructureConfigurations_606627;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of infrastructure configurations. 
  ## 
  let valid = call_606640.validator(path, query, header, formData, body)
  let scheme = call_606640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606640.url(scheme.get, call_606640.host, call_606640.base,
                         call_606640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606640, url, valid)

proc call*(call_606641: Call_ListInfrastructureConfigurations_606627;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listInfrastructureConfigurations
  ##  Returns a list of infrastructure configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606642 = newJObject()
  var body_606643 = newJObject()
  add(query_606642, "nextToken", newJString(nextToken))
  if body != nil:
    body_606643 = body
  add(query_606642, "maxResults", newJString(maxResults))
  result = call_606641.call(nil, query_606642, nil, nil, body_606643)

var listInfrastructureConfigurations* = Call_ListInfrastructureConfigurations_606627(
    name: "listInfrastructureConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListInfrastructureConfigurations",
    validator: validate_ListInfrastructureConfigurations_606628, base: "/",
    url: url_ListInfrastructureConfigurations_606629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606672 = ref object of OpenApiRestCall_605589
proc url_TagResource_606674(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606673(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Adds a tag to a resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to tag. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606675 = path.getOrDefault("resourceArn")
  valid_606675 = validateParameter(valid_606675, JString, required = true,
                                 default = nil)
  if valid_606675 != nil:
    section.add "resourceArn", valid_606675
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606676 = header.getOrDefault("X-Amz-Signature")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Signature", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Content-Sha256", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Date")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Date", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Credential")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Credential", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Security-Token")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Security-Token", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Algorithm")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Algorithm", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-SignedHeaders", valid_606682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606684: Call_TagResource_606672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Adds a tag to a resource. 
  ## 
  let valid = call_606684.validator(path, query, header, formData, body)
  let scheme = call_606684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606684.url(scheme.get, call_606684.host, call_606684.base,
                         call_606684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606684, url, valid)

proc call*(call_606685: Call_TagResource_606672; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Adds a tag to a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to tag. 
  ##   body: JObject (required)
  var path_606686 = newJObject()
  var body_606687 = newJObject()
  add(path_606686, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606687 = body
  result = call_606685.call(path_606686, nil, nil, nil, body_606687)

var tagResource* = Call_TagResource_606672(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606673,
                                        base: "/", url: url_TagResource_606674,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606644 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606646(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606645(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Returns the list of tags for the specified resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you wish to retrieve. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606661 = path.getOrDefault("resourceArn")
  valid_606661 = validateParameter(valid_606661, JString, required = true,
                                 default = nil)
  if valid_606661 != nil:
    section.add "resourceArn", valid_606661
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606662 = header.getOrDefault("X-Amz-Signature")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Signature", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Content-Sha256", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Date")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Date", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Credential")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Credential", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Security-Token")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Security-Token", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Algorithm")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Algorithm", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-SignedHeaders", valid_606668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606669: Call_ListTagsForResource_606644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of tags for the specified resource. 
  ## 
  let valid = call_606669.validator(path, query, header, formData, body)
  let scheme = call_606669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606669.url(scheme.get, call_606669.host, call_606669.base,
                         call_606669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606669, url, valid)

proc call*(call_606670: Call_ListTagsForResource_606644; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  Returns the list of tags for the specified resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you wish to retrieve. 
  var path_606671 = newJObject()
  add(path_606671, "resourceArn", newJString(resourceArn))
  result = call_606670.call(path_606671, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606644(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606645, base: "/",
    url: url_ListTagsForResource_606646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComponentPolicy_606688 = ref object of OpenApiRestCall_605589
proc url_PutComponentPolicy_606690(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComponentPolicy_606689(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Applies a policy to a component. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606691 = header.getOrDefault("X-Amz-Signature")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Signature", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Content-Sha256", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Date")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Date", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Credential")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Credential", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Security-Token")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Security-Token", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Algorithm")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Algorithm", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-SignedHeaders", valid_606697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606699: Call_PutComponentPolicy_606688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to a component. 
  ## 
  let valid = call_606699.validator(path, query, header, formData, body)
  let scheme = call_606699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606699.url(scheme.get, call_606699.host, call_606699.base,
                         call_606699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606699, url, valid)

proc call*(call_606700: Call_PutComponentPolicy_606688; body: JsonNode): Recallable =
  ## putComponentPolicy
  ##  Applies a policy to a component. 
  ##   body: JObject (required)
  var body_606701 = newJObject()
  if body != nil:
    body_606701 = body
  result = call_606700.call(nil, nil, nil, nil, body_606701)

var putComponentPolicy* = Call_PutComponentPolicy_606688(
    name: "putComponentPolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutComponentPolicy",
    validator: validate_PutComponentPolicy_606689, base: "/",
    url: url_PutComponentPolicy_606690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImagePolicy_606702 = ref object of OpenApiRestCall_605589
proc url_PutImagePolicy_606704(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImagePolicy_606703(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Applies a policy to an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606705 = header.getOrDefault("X-Amz-Signature")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Signature", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Content-Sha256", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Date")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Date", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Credential")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Credential", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Security-Token")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Security-Token", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Algorithm")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Algorithm", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-SignedHeaders", valid_606711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606713: Call_PutImagePolicy_606702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image. 
  ## 
  let valid = call_606713.validator(path, query, header, formData, body)
  let scheme = call_606713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606713.url(scheme.get, call_606713.host, call_606713.base,
                         call_606713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606713, url, valid)

proc call*(call_606714: Call_PutImagePolicy_606702; body: JsonNode): Recallable =
  ## putImagePolicy
  ##  Applies a policy to an image. 
  ##   body: JObject (required)
  var body_606715 = newJObject()
  if body != nil:
    body_606715 = body
  result = call_606714.call(nil, nil, nil, nil, body_606715)

var putImagePolicy* = Call_PutImagePolicy_606702(name: "putImagePolicy",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/PutImagePolicy", validator: validate_PutImagePolicy_606703, base: "/",
    url: url_PutImagePolicy_606704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageRecipePolicy_606716 = ref object of OpenApiRestCall_605589
proc url_PutImageRecipePolicy_606718(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageRecipePolicy_606717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Applies a policy to an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606719 = header.getOrDefault("X-Amz-Signature")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Signature", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Content-Sha256", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Date")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Date", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Credential")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Credential", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Security-Token")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Security-Token", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Algorithm")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Algorithm", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-SignedHeaders", valid_606725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606727: Call_PutImageRecipePolicy_606716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image recipe. 
  ## 
  let valid = call_606727.validator(path, query, header, formData, body)
  let scheme = call_606727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606727.url(scheme.get, call_606727.host, call_606727.base,
                         call_606727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606727, url, valid)

proc call*(call_606728: Call_PutImageRecipePolicy_606716; body: JsonNode): Recallable =
  ## putImageRecipePolicy
  ##  Applies a policy to an image recipe. 
  ##   body: JObject (required)
  var body_606729 = newJObject()
  if body != nil:
    body_606729 = body
  result = call_606728.call(nil, nil, nil, nil, body_606729)

var putImageRecipePolicy* = Call_PutImageRecipePolicy_606716(
    name: "putImageRecipePolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutImageRecipePolicy",
    validator: validate_PutImageRecipePolicy_606717, base: "/",
    url: url_PutImageRecipePolicy_606718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImagePipelineExecution_606730 = ref object of OpenApiRestCall_605589
proc url_StartImagePipelineExecution_606732(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImagePipelineExecution_606731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606733 = header.getOrDefault("X-Amz-Signature")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Signature", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Content-Sha256", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Date")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Date", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Credential")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Credential", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Security-Token")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Security-Token", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Algorithm")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Algorithm", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-SignedHeaders", valid_606739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606741: Call_StartImagePipelineExecution_606730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  let valid = call_606741.validator(path, query, header, formData, body)
  let scheme = call_606741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606741.url(scheme.get, call_606741.host, call_606741.base,
                         call_606741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606741, url, valid)

proc call*(call_606742: Call_StartImagePipelineExecution_606730; body: JsonNode): Recallable =
  ## startImagePipelineExecution
  ##  Manually triggers a pipeline to create an image. 
  ##   body: JObject (required)
  var body_606743 = newJObject()
  if body != nil:
    body_606743 = body
  result = call_606742.call(nil, nil, nil, nil, body_606743)

var startImagePipelineExecution* = Call_StartImagePipelineExecution_606730(
    name: "startImagePipelineExecution", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/StartImagePipelineExecution",
    validator: validate_StartImagePipelineExecution_606731, base: "/",
    url: url_StartImagePipelineExecution_606732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606744 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606746(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606745(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Removes a tag from a resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to untag. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606747 = path.getOrDefault("resourceArn")
  valid_606747 = validateParameter(valid_606747, JString, required = true,
                                 default = nil)
  if valid_606747 != nil:
    section.add "resourceArn", valid_606747
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606748 = query.getOrDefault("tagKeys")
  valid_606748 = validateParameter(valid_606748, JArray, required = true, default = nil)
  if valid_606748 != nil:
    section.add "tagKeys", valid_606748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606749 = header.getOrDefault("X-Amz-Signature")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Signature", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Content-Sha256", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Date")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Date", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Credential")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Credential", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Security-Token")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Security-Token", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Algorithm")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Algorithm", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-SignedHeaders", valid_606755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606756: Call_UntagResource_606744; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Removes a tag from a resource. 
  ## 
  let valid = call_606756.validator(path, query, header, formData, body)
  let scheme = call_606756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606756.url(scheme.get, call_606756.host, call_606756.base,
                         call_606756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606756, url, valid)

proc call*(call_606757: Call_UntagResource_606744; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Removes a tag from a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to untag. 
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  var path_606758 = newJObject()
  var query_606759 = newJObject()
  add(path_606758, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606759.add "tagKeys", tagKeys
  result = call_606757.call(path_606758, query_606759, nil, nil, nil)

var untagResource* = Call_UntagResource_606744(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606745,
    base: "/", url: url_UntagResource_606746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistributionConfiguration_606760 = ref object of OpenApiRestCall_605589
proc url_UpdateDistributionConfiguration_606762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDistributionConfiguration_606761(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606763 = header.getOrDefault("X-Amz-Signature")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Signature", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Content-Sha256", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Date")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Date", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Credential")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Credential", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Security-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Security-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Algorithm")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Algorithm", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-SignedHeaders", valid_606769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606771: Call_UpdateDistributionConfiguration_606760;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_606771.validator(path, query, header, formData, body)
  let scheme = call_606771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606771.url(scheme.get, call_606771.host, call_606771.base,
                         call_606771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606771, url, valid)

proc call*(call_606772: Call_UpdateDistributionConfiguration_606760; body: JsonNode): Recallable =
  ## updateDistributionConfiguration
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_606773 = newJObject()
  if body != nil:
    body_606773 = body
  result = call_606772.call(nil, nil, nil, nil, body_606773)

var updateDistributionConfiguration* = Call_UpdateDistributionConfiguration_606760(
    name: "updateDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateDistributionConfiguration",
    validator: validate_UpdateDistributionConfiguration_606761, base: "/",
    url: url_UpdateDistributionConfiguration_606762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePipeline_606774 = ref object of OpenApiRestCall_605589
proc url_UpdateImagePipeline_606776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateImagePipeline_606775(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606777 = header.getOrDefault("X-Amz-Signature")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Signature", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Content-Sha256", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Date")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Date", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Credential")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Credential", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Security-Token")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Security-Token", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Algorithm")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Algorithm", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-SignedHeaders", valid_606783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_UpdateImagePipeline_606774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_UpdateImagePipeline_606774; body: JsonNode): Recallable =
  ## updateImagePipeline
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_606787 = newJObject()
  if body != nil:
    body_606787 = body
  result = call_606786.call(nil, nil, nil, nil, body_606787)

var updateImagePipeline* = Call_UpdateImagePipeline_606774(
    name: "updateImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateImagePipeline",
    validator: validate_UpdateImagePipeline_606775, base: "/",
    url: url_UpdateImagePipeline_606776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInfrastructureConfiguration_606788 = ref object of OpenApiRestCall_605589
proc url_UpdateInfrastructureConfiguration_606790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInfrastructureConfiguration_606789(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606791 = header.getOrDefault("X-Amz-Signature")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Signature", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Content-Sha256", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Date")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Date", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Credential")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Credential", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Security-Token")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Security-Token", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Algorithm")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Algorithm", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-SignedHeaders", valid_606797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606799: Call_UpdateInfrastructureConfiguration_606788;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_606799.validator(path, query, header, formData, body)
  let scheme = call_606799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606799.url(scheme.get, call_606799.host, call_606799.base,
                         call_606799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606799, url, valid)

proc call*(call_606800: Call_UpdateInfrastructureConfiguration_606788;
          body: JsonNode): Recallable =
  ## updateInfrastructureConfiguration
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_606801 = newJObject()
  if body != nil:
    body_606801 = body
  result = call_606800.call(nil, nil, nil, nil, body_606801)

var updateInfrastructureConfiguration* = Call_UpdateInfrastructureConfiguration_606788(
    name: "updateInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateInfrastructureConfiguration",
    validator: validate_UpdateInfrastructureConfiguration_606789, base: "/",
    url: url_UpdateInfrastructureConfiguration_606790,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
