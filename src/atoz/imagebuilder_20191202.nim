
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CancelImageCreation_601727 = ref object of OpenApiRestCall_601389
proc url_CancelImageCreation_601729(protocol: Scheme; host: string; base: string;
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

proc validate_CancelImageCreation_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_CancelImageCreation_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_CancelImageCreation_601727; body: JsonNode): Recallable =
  ## cancelImageCreation
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ##   body: JObject (required)
  var body_601943 = newJObject()
  if body != nil:
    body_601943 = body
  result = call_601942.call(nil, nil, nil, nil, body_601943)

var cancelImageCreation* = Call_CancelImageCreation_601727(
    name: "cancelImageCreation", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CancelImageCreation",
    validator: validate_CancelImageCreation_601728, base: "/",
    url: url_CancelImageCreation_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_601982 = ref object of OpenApiRestCall_601389
proc url_CreateComponent_601984(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComponent_601983(path: JsonNode; query: JsonNode;
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
  var valid_601985 = header.getOrDefault("X-Amz-Signature")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Signature", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Content-Sha256", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Date")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Date", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Credential")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Credential", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Security-Token")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Security-Token", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Algorithm")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Algorithm", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-SignedHeaders", valid_601991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_CreateComponent_601982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ## 
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601993, url, valid)

proc call*(call_601994: Call_CreateComponent_601982; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ##   body: JObject (required)
  var body_601995 = newJObject()
  if body != nil:
    body_601995 = body
  result = call_601994.call(nil, nil, nil, nil, body_601995)

var createComponent* = Call_CreateComponent_601982(name: "createComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateComponent", validator: validate_CreateComponent_601983,
    base: "/", url: url_CreateComponent_601984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionConfiguration_601996 = ref object of OpenApiRestCall_601389
proc url_CreateDistributionConfiguration_601998(protocol: Scheme; host: string;
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

proc validate_CreateDistributionConfiguration_601997(path: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Signature")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Signature", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Content-Sha256", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Date")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Date", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Credential")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Credential", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Security-Token")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Security-Token", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Algorithm")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Algorithm", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-SignedHeaders", valid_602005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602007: Call_CreateDistributionConfiguration_601996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_602007.validator(path, query, header, formData, body)
  let scheme = call_602007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602007.url(scheme.get, call_602007.host, call_602007.base,
                         call_602007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602007, url, valid)

proc call*(call_602008: Call_CreateDistributionConfiguration_601996; body: JsonNode): Recallable =
  ## createDistributionConfiguration
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_602009 = newJObject()
  if body != nil:
    body_602009 = body
  result = call_602008.call(nil, nil, nil, nil, body_602009)

var createDistributionConfiguration* = Call_CreateDistributionConfiguration_601996(
    name: "createDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateDistributionConfiguration",
    validator: validate_CreateDistributionConfiguration_601997, base: "/",
    url: url_CreateDistributionConfiguration_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImage_602010 = ref object of OpenApiRestCall_601389
proc url_CreateImage_602012(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImage_602011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Content-Sha256", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Date")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Date", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Credential")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Credential", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Security-Token")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Security-Token", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Algorithm")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Algorithm", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-SignedHeaders", valid_602019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602021: Call_CreateImage_602010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  let valid = call_602021.validator(path, query, header, formData, body)
  let scheme = call_602021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602021.url(scheme.get, call_602021.host, call_602021.base,
                         call_602021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602021, url, valid)

proc call*(call_602022: Call_CreateImage_602010; body: JsonNode): Recallable =
  ## createImage
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ##   body: JObject (required)
  var body_602023 = newJObject()
  if body != nil:
    body_602023 = body
  result = call_602022.call(nil, nil, nil, nil, body_602023)

var createImage* = Call_CreateImage_602010(name: "createImage",
                                        meth: HttpMethod.HttpPut,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/CreateImage",
                                        validator: validate_CreateImage_602011,
                                        base: "/", url: url_CreateImage_602012,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImagePipeline_602024 = ref object of OpenApiRestCall_601389
proc url_CreateImagePipeline_602026(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImagePipeline_602025(path: JsonNode; query: JsonNode;
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
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Security-Token")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Security-Token", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602035: Call_CreateImagePipeline_602024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_602035.validator(path, query, header, formData, body)
  let scheme = call_602035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602035.url(scheme.get, call_602035.host, call_602035.base,
                         call_602035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602035, url, valid)

proc call*(call_602036: Call_CreateImagePipeline_602024; body: JsonNode): Recallable =
  ## createImagePipeline
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_602037 = newJObject()
  if body != nil:
    body_602037 = body
  result = call_602036.call(nil, nil, nil, nil, body_602037)

var createImagePipeline* = Call_CreateImagePipeline_602024(
    name: "createImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImagePipeline",
    validator: validate_CreateImagePipeline_602025, base: "/",
    url: url_CreateImagePipeline_602026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageRecipe_602038 = ref object of OpenApiRestCall_601389
proc url_CreateImageRecipe_602040(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImageRecipe_602039(path: JsonNode; query: JsonNode;
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
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Content-Sha256", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-SignedHeaders", valid_602047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602049: Call_CreateImageRecipe_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ## 
  let valid = call_602049.validator(path, query, header, formData, body)
  let scheme = call_602049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602049.url(scheme.get, call_602049.host, call_602049.base,
                         call_602049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602049, url, valid)

proc call*(call_602050: Call_CreateImageRecipe_602038; body: JsonNode): Recallable =
  ## createImageRecipe
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ##   body: JObject (required)
  var body_602051 = newJObject()
  if body != nil:
    body_602051 = body
  result = call_602050.call(nil, nil, nil, nil, body_602051)

var createImageRecipe* = Call_CreateImageRecipe_602038(name: "createImageRecipe",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateImageRecipe", validator: validate_CreateImageRecipe_602039,
    base: "/", url: url_CreateImageRecipe_602040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInfrastructureConfiguration_602052 = ref object of OpenApiRestCall_601389
proc url_CreateInfrastructureConfiguration_602054(protocol: Scheme; host: string;
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

proc validate_CreateInfrastructureConfiguration_602053(path: JsonNode;
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
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Content-Sha256", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Date")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Date", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Credential")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Credential", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Security-Token")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Security-Token", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Algorithm")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Algorithm", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-SignedHeaders", valid_602061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_CreateInfrastructureConfiguration_602052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602063, url, valid)

proc call*(call_602064: Call_CreateInfrastructureConfiguration_602052;
          body: JsonNode): Recallable =
  ## createInfrastructureConfiguration
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_602065 = newJObject()
  if body != nil:
    body_602065 = body
  result = call_602064.call(nil, nil, nil, nil, body_602065)

var createInfrastructureConfiguration* = Call_CreateInfrastructureConfiguration_602052(
    name: "createInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateInfrastructureConfiguration",
    validator: validate_CreateInfrastructureConfiguration_602053, base: "/",
    url: url_CreateInfrastructureConfiguration_602054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_602066 = ref object of OpenApiRestCall_601389
proc url_DeleteComponent_602068(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComponent_602067(path: JsonNode; query: JsonNode;
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
  var valid_602069 = query.getOrDefault("componentBuildVersionArn")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "componentBuildVersionArn", valid_602069
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
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Content-Sha256", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Date")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Date", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Credential")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Credential", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Security-Token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Security-Token", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Algorithm")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Algorithm", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-SignedHeaders", valid_602076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_DeleteComponent_602066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a component build version. 
  ## 
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602077, url, valid)

proc call*(call_602078: Call_DeleteComponent_602066;
          componentBuildVersionArn: string): Recallable =
  ## deleteComponent
  ##  Deletes a component build version. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  var query_602079 = newJObject()
  add(query_602079, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_602078.call(nil, query_602079, nil, nil, nil)

var deleteComponent* = Call_DeleteComponent_602066(name: "deleteComponent",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteComponent#componentBuildVersionArn",
    validator: validate_DeleteComponent_602067, base: "/", url: url_DeleteComponent_602068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistributionConfiguration_602081 = ref object of OpenApiRestCall_601389
proc url_DeleteDistributionConfiguration_602083(protocol: Scheme; host: string;
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

proc validate_DeleteDistributionConfiguration_602082(path: JsonNode;
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
  var valid_602084 = query.getOrDefault("distributionConfigurationArn")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = nil)
  if valid_602084 != nil:
    section.add "distributionConfigurationArn", valid_602084
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
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Content-Sha256", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Date")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Date", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Credential")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Credential", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Security-Token")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Security-Token", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Algorithm")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Algorithm", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-SignedHeaders", valid_602091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_DeleteDistributionConfiguration_602081;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes a distribution configuration. 
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602092, url, valid)

proc call*(call_602093: Call_DeleteDistributionConfiguration_602081;
          distributionConfigurationArn: string): Recallable =
  ## deleteDistributionConfiguration
  ##  Deletes a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  var query_602094 = newJObject()
  add(query_602094, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_602093.call(nil, query_602094, nil, nil, nil)

var deleteDistributionConfiguration* = Call_DeleteDistributionConfiguration_602081(
    name: "deleteDistributionConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteDistributionConfiguration#distributionConfigurationArn",
    validator: validate_DeleteDistributionConfiguration_602082, base: "/",
    url: url_DeleteDistributionConfiguration_602083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_602095 = ref object of OpenApiRestCall_601389
proc url_DeleteImage_602097(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImage_602096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602098 = query.getOrDefault("imageBuildVersionArn")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "imageBuildVersionArn", valid_602098
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
  var valid_602099 = header.getOrDefault("X-Amz-Signature")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Signature", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Content-Sha256", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Date")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Date", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Credential")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Credential", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Security-Token")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Security-Token", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Algorithm")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Algorithm", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-SignedHeaders", valid_602105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602106: Call_DeleteImage_602095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image. 
  ## 
  let valid = call_602106.validator(path, query, header, formData, body)
  let scheme = call_602106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602106.url(scheme.get, call_602106.host, call_602106.base,
                         call_602106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602106, url, valid)

proc call*(call_602107: Call_DeleteImage_602095; imageBuildVersionArn: string): Recallable =
  ## deleteImage
  ##  Deletes an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  var query_602108 = newJObject()
  add(query_602108, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_602107.call(nil, query_602108, nil, nil, nil)

var deleteImage* = Call_DeleteImage_602095(name: "deleteImage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "imagebuilder.amazonaws.com", route: "/DeleteImage#imageBuildVersionArn",
                                        validator: validate_DeleteImage_602096,
                                        base: "/", url: url_DeleteImage_602097,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePipeline_602109 = ref object of OpenApiRestCall_601389
proc url_DeleteImagePipeline_602111(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImagePipeline_602110(path: JsonNode; query: JsonNode;
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
  var valid_602112 = query.getOrDefault("imagePipelineArn")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = nil)
  if valid_602112 != nil:
    section.add "imagePipelineArn", valid_602112
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
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Content-Sha256", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Credential")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Credential", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Security-Token")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Security-Token", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-SignedHeaders", valid_602119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_DeleteImagePipeline_602109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image pipeline. 
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_DeleteImagePipeline_602109; imagePipelineArn: string): Recallable =
  ## deleteImagePipeline
  ##  Deletes an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  var query_602122 = newJObject()
  add(query_602122, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_602121.call(nil, query_602122, nil, nil, nil)

var deleteImagePipeline* = Call_DeleteImagePipeline_602109(
    name: "deleteImagePipeline", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImagePipeline#imagePipelineArn",
    validator: validate_DeleteImagePipeline_602110, base: "/",
    url: url_DeleteImagePipeline_602111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageRecipe_602123 = ref object of OpenApiRestCall_601389
proc url_DeleteImageRecipe_602125(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImageRecipe_602124(path: JsonNode; query: JsonNode;
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
  var valid_602126 = query.getOrDefault("imageRecipeArn")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = nil)
  if valid_602126 != nil:
    section.add "imageRecipeArn", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Signature")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Signature", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Date")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Date", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Algorithm")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Algorithm", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-SignedHeaders", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_DeleteImageRecipe_602123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image recipe. 
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_DeleteImageRecipe_602123; imageRecipeArn: string): Recallable =
  ## deleteImageRecipe
  ##  Deletes an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  var query_602136 = newJObject()
  add(query_602136, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_602135.call(nil, query_602136, nil, nil, nil)

var deleteImageRecipe* = Call_DeleteImageRecipe_602123(name: "deleteImageRecipe",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteImageRecipe#imageRecipeArn",
    validator: validate_DeleteImageRecipe_602124, base: "/",
    url: url_DeleteImageRecipe_602125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInfrastructureConfiguration_602137 = ref object of OpenApiRestCall_601389
proc url_DeleteInfrastructureConfiguration_602139(protocol: Scheme; host: string;
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

proc validate_DeleteInfrastructureConfiguration_602138(path: JsonNode;
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
  var valid_602140 = query.getOrDefault("infrastructureConfigurationArn")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = nil)
  if valid_602140 != nil:
    section.add "infrastructureConfigurationArn", valid_602140
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
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602148: Call_DeleteInfrastructureConfiguration_602137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes an infrastructure configuration. 
  ## 
  let valid = call_602148.validator(path, query, header, formData, body)
  let scheme = call_602148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602148.url(scheme.get, call_602148.host, call_602148.base,
                         call_602148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602148, url, valid)

proc call*(call_602149: Call_DeleteInfrastructureConfiguration_602137;
          infrastructureConfigurationArn: string): Recallable =
  ## deleteInfrastructureConfiguration
  ##  Deletes an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  var query_602150 = newJObject()
  add(query_602150, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_602149.call(nil, query_602150, nil, nil, nil)

var deleteInfrastructureConfiguration* = Call_DeleteInfrastructureConfiguration_602137(
    name: "deleteInfrastructureConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_DeleteInfrastructureConfiguration_602138, base: "/",
    url: url_DeleteInfrastructureConfiguration_602139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponent_602151 = ref object of OpenApiRestCall_601389
proc url_GetComponent_602153(protocol: Scheme; host: string; base: string;
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

proc validate_GetComponent_602152(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602154 = query.getOrDefault("componentBuildVersionArn")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = nil)
  if valid_602154 != nil:
    section.add "componentBuildVersionArn", valid_602154
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
  var valid_602155 = header.getOrDefault("X-Amz-Signature")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Signature", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Content-Sha256", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Credential")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Credential", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Security-Token")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Security-Token", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_GetComponent_602151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component object. 
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_GetComponent_602151; componentBuildVersionArn: string): Recallable =
  ## getComponent
  ##  Gets a component object. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you wish to retrieve. 
  var query_602164 = newJObject()
  add(query_602164, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_602163.call(nil, query_602164, nil, nil, nil)

var getComponent* = Call_GetComponent_602151(name: "getComponent",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetComponent#componentBuildVersionArn",
    validator: validate_GetComponent_602152, base: "/", url: url_GetComponent_602153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponentPolicy_602165 = ref object of OpenApiRestCall_601389
proc url_GetComponentPolicy_602167(protocol: Scheme; host: string; base: string;
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

proc validate_GetComponentPolicy_602166(path: JsonNode; query: JsonNode;
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
  var valid_602168 = query.getOrDefault("componentArn")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "componentArn", valid_602168
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
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Content-Sha256", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Credential")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Credential", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Security-Token")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Security-Token", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602176: Call_GetComponentPolicy_602165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component policy. 
  ## 
  let valid = call_602176.validator(path, query, header, formData, body)
  let scheme = call_602176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602176.url(scheme.get, call_602176.host, call_602176.base,
                         call_602176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602176, url, valid)

proc call*(call_602177: Call_GetComponentPolicy_602165; componentArn: string): Recallable =
  ## getComponentPolicy
  ##  Gets a component policy. 
  ##   componentArn: string (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you wish to retrieve. 
  var query_602178 = newJObject()
  add(query_602178, "componentArn", newJString(componentArn))
  result = call_602177.call(nil, query_602178, nil, nil, nil)

var getComponentPolicy* = Call_GetComponentPolicy_602165(
    name: "getComponentPolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/GetComponentPolicy#componentArn",
    validator: validate_GetComponentPolicy_602166, base: "/",
    url: url_GetComponentPolicy_602167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfiguration_602179 = ref object of OpenApiRestCall_601389
proc url_GetDistributionConfiguration_602181(protocol: Scheme; host: string;
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

proc validate_GetDistributionConfiguration_602180(path: JsonNode; query: JsonNode;
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
  var valid_602182 = query.getOrDefault("distributionConfigurationArn")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = nil)
  if valid_602182 != nil:
    section.add "distributionConfigurationArn", valid_602182
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
  var valid_602183 = header.getOrDefault("X-Amz-Signature")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Signature", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Content-Sha256", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Date")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Date", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Credential")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Credential", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Security-Token")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Security-Token", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Algorithm")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Algorithm", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-SignedHeaders", valid_602189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602190: Call_GetDistributionConfiguration_602179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a distribution configuration. 
  ## 
  let valid = call_602190.validator(path, query, header, formData, body)
  let scheme = call_602190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602190.url(scheme.get, call_602190.host, call_602190.base,
                         call_602190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602190, url, valid)

proc call*(call_602191: Call_GetDistributionConfiguration_602179;
          distributionConfigurationArn: string): Recallable =
  ## getDistributionConfiguration
  ##  Gets a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you wish to retrieve. 
  var query_602192 = newJObject()
  add(query_602192, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_602191.call(nil, query_602192, nil, nil, nil)

var getDistributionConfiguration* = Call_GetDistributionConfiguration_602179(
    name: "getDistributionConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetDistributionConfiguration#distributionConfigurationArn",
    validator: validate_GetDistributionConfiguration_602180, base: "/",
    url: url_GetDistributionConfiguration_602181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImage_602193 = ref object of OpenApiRestCall_601389
proc url_GetImage_602195(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetImage_602194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602196 = query.getOrDefault("imageBuildVersionArn")
  valid_602196 = validateParameter(valid_602196, JString, required = true,
                                 default = nil)
  if valid_602196 != nil:
    section.add "imageBuildVersionArn", valid_602196
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
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Date")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Date", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Credential")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Credential", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Security-Token")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Security-Token", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Algorithm")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Algorithm", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-SignedHeaders", valid_602203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_GetImage_602193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image. 
  ## 
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602204, url, valid)

proc call*(call_602205: Call_GetImage_602193; imageBuildVersionArn: string): Recallable =
  ## getImage
  ##  Gets an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you wish to retrieve. 
  var query_602206 = newJObject()
  add(query_602206, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_602205.call(nil, query_602206, nil, nil, nil)

var getImage* = Call_GetImage_602193(name: "getImage", meth: HttpMethod.HttpGet,
                                  host: "imagebuilder.amazonaws.com",
                                  route: "/GetImage#imageBuildVersionArn",
                                  validator: validate_GetImage_602194, base: "/",
                                  url: url_GetImage_602195,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePipeline_602207 = ref object of OpenApiRestCall_601389
proc url_GetImagePipeline_602209(protocol: Scheme; host: string; base: string;
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

proc validate_GetImagePipeline_602208(path: JsonNode; query: JsonNode;
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
  var valid_602210 = query.getOrDefault("imagePipelineArn")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "imagePipelineArn", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_GetImagePipeline_602207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image pipeline. 
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_GetImagePipeline_602207; imagePipelineArn: string): Recallable =
  ## getImagePipeline
  ##  Gets an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you wish to retrieve. 
  var query_602220 = newJObject()
  add(query_602220, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_602219.call(nil, query_602220, nil, nil, nil)

var getImagePipeline* = Call_GetImagePipeline_602207(name: "getImagePipeline",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePipeline#imagePipelineArn",
    validator: validate_GetImagePipeline_602208, base: "/",
    url: url_GetImagePipeline_602209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePolicy_602221 = ref object of OpenApiRestCall_601389
proc url_GetImagePolicy_602223(protocol: Scheme; host: string; base: string;
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

proc validate_GetImagePolicy_602222(path: JsonNode; query: JsonNode;
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
  var valid_602224 = query.getOrDefault("imageArn")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "imageArn", valid_602224
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
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602232: Call_GetImagePolicy_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image policy. 
  ## 
  let valid = call_602232.validator(path, query, header, formData, body)
  let scheme = call_602232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602232.url(scheme.get, call_602232.host, call_602232.base,
                         call_602232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602232, url, valid)

proc call*(call_602233: Call_GetImagePolicy_602221; imageArn: string): Recallable =
  ## getImagePolicy
  ##  Gets an image policy. 
  ##   imageArn: string (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you wish to retrieve. 
  var query_602234 = newJObject()
  add(query_602234, "imageArn", newJString(imageArn))
  result = call_602233.call(nil, query_602234, nil, nil, nil)

var getImagePolicy* = Call_GetImagePolicy_602221(name: "getImagePolicy",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePolicy#imageArn", validator: validate_GetImagePolicy_602222,
    base: "/", url: url_GetImagePolicy_602223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipe_602235 = ref object of OpenApiRestCall_601389
proc url_GetImageRecipe_602237(protocol: Scheme; host: string; base: string;
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

proc validate_GetImageRecipe_602236(path: JsonNode; query: JsonNode;
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
  var valid_602238 = query.getOrDefault("imageRecipeArn")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "imageRecipeArn", valid_602238
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
  var valid_602239 = header.getOrDefault("X-Amz-Signature")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Signature", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Content-Sha256", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Date")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Date", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Credential")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Credential", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Security-Token")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Security-Token", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Algorithm")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Algorithm", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-SignedHeaders", valid_602245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602246: Call_GetImageRecipe_602235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe. 
  ## 
  let valid = call_602246.validator(path, query, header, formData, body)
  let scheme = call_602246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602246.url(scheme.get, call_602246.host, call_602246.base,
                         call_602246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602246, url, valid)

proc call*(call_602247: Call_GetImageRecipe_602235; imageRecipeArn: string): Recallable =
  ## getImageRecipe
  ##  Gets an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you wish to retrieve. 
  var query_602248 = newJObject()
  add(query_602248, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_602247.call(nil, query_602248, nil, nil, nil)

var getImageRecipe* = Call_GetImageRecipe_602235(name: "getImageRecipe",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipe#imageRecipeArn", validator: validate_GetImageRecipe_602236,
    base: "/", url: url_GetImageRecipe_602237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipePolicy_602249 = ref object of OpenApiRestCall_601389
proc url_GetImageRecipePolicy_602251(protocol: Scheme; host: string; base: string;
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

proc validate_GetImageRecipePolicy_602250(path: JsonNode; query: JsonNode;
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
  var valid_602252 = query.getOrDefault("imageRecipeArn")
  valid_602252 = validateParameter(valid_602252, JString, required = true,
                                 default = nil)
  if valid_602252 != nil:
    section.add "imageRecipeArn", valid_602252
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
  var valid_602253 = header.getOrDefault("X-Amz-Signature")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Signature", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Content-Sha256", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Date")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Date", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Credential")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Credential", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Security-Token")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Security-Token", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Algorithm")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Algorithm", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-SignedHeaders", valid_602259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602260: Call_GetImageRecipePolicy_602249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe policy. 
  ## 
  let valid = call_602260.validator(path, query, header, formData, body)
  let scheme = call_602260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602260.url(scheme.get, call_602260.host, call_602260.base,
                         call_602260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602260, url, valid)

proc call*(call_602261: Call_GetImageRecipePolicy_602249; imageRecipeArn: string): Recallable =
  ## getImageRecipePolicy
  ##  Gets an image recipe policy. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you wish to retrieve. 
  var query_602262 = newJObject()
  add(query_602262, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_602261.call(nil, query_602262, nil, nil, nil)

var getImageRecipePolicy* = Call_GetImageRecipePolicy_602249(
    name: "getImageRecipePolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipePolicy#imageRecipeArn",
    validator: validate_GetImageRecipePolicy_602250, base: "/",
    url: url_GetImageRecipePolicy_602251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInfrastructureConfiguration_602263 = ref object of OpenApiRestCall_601389
proc url_GetInfrastructureConfiguration_602265(protocol: Scheme; host: string;
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

proc validate_GetInfrastructureConfiguration_602264(path: JsonNode;
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
  var valid_602266 = query.getOrDefault("infrastructureConfigurationArn")
  valid_602266 = validateParameter(valid_602266, JString, required = true,
                                 default = nil)
  if valid_602266 != nil:
    section.add "infrastructureConfigurationArn", valid_602266
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
  var valid_602267 = header.getOrDefault("X-Amz-Signature")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Signature", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Content-Sha256", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Date")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Date", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Credential")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Credential", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Security-Token")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Security-Token", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Algorithm")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Algorithm", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-SignedHeaders", valid_602273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602274: Call_GetInfrastructureConfiguration_602263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a infrastructure configuration. 
  ## 
  let valid = call_602274.validator(path, query, header, formData, body)
  let scheme = call_602274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602274.url(scheme.get, call_602274.host, call_602274.base,
                         call_602274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602274, url, valid)

proc call*(call_602275: Call_GetInfrastructureConfiguration_602263;
          infrastructureConfigurationArn: string): Recallable =
  ## getInfrastructureConfiguration
  ##  Gets a infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration that you wish to retrieve. 
  var query_602276 = newJObject()
  add(query_602276, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_602275.call(nil, query_602276, nil, nil, nil)

var getInfrastructureConfiguration* = Call_GetInfrastructureConfiguration_602263(
    name: "getInfrastructureConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_GetInfrastructureConfiguration_602264, base: "/",
    url: url_GetInfrastructureConfiguration_602265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportComponent_602277 = ref object of OpenApiRestCall_601389
proc url_ImportComponent_602279(protocol: Scheme; host: string; base: string;
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

proc validate_ImportComponent_602278(path: JsonNode; query: JsonNode;
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
  var valid_602280 = header.getOrDefault("X-Amz-Signature")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Signature", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Content-Sha256", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Date")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Date", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Credential")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Credential", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Security-Token")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Security-Token", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Algorithm")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Algorithm", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-SignedHeaders", valid_602286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602288: Call_ImportComponent_602277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports a component and transforms its data into a component document. 
  ## 
  let valid = call_602288.validator(path, query, header, formData, body)
  let scheme = call_602288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602288.url(scheme.get, call_602288.host, call_602288.base,
                         call_602288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602288, url, valid)

proc call*(call_602289: Call_ImportComponent_602277; body: JsonNode): Recallable =
  ## importComponent
  ##  Imports a component and transforms its data into a component document. 
  ##   body: JObject (required)
  var body_602290 = newJObject()
  if body != nil:
    body_602290 = body
  result = call_602289.call(nil, nil, nil, nil, body_602290)

var importComponent* = Call_ImportComponent_602277(name: "importComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/ImportComponent", validator: validate_ImportComponent_602278,
    base: "/", url: url_ImportComponent_602279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponentBuildVersions_602291 = ref object of OpenApiRestCall_601389
proc url_ListComponentBuildVersions_602293(protocol: Scheme; host: string;
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

proc validate_ListComponentBuildVersions_602292(path: JsonNode; query: JsonNode;
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
  var valid_602294 = query.getOrDefault("nextToken")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "nextToken", valid_602294
  var valid_602295 = query.getOrDefault("maxResults")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "maxResults", valid_602295
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
  var valid_602296 = header.getOrDefault("X-Amz-Signature")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Signature", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Content-Sha256", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Date")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Date", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Credential")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Credential", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Security-Token")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Security-Token", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Algorithm")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Algorithm", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-SignedHeaders", valid_602302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602304: Call_ListComponentBuildVersions_602291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_602304.validator(path, query, header, formData, body)
  let scheme = call_602304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602304.url(scheme.get, call_602304.host, call_602304.base,
                         call_602304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602304, url, valid)

proc call*(call_602305: Call_ListComponentBuildVersions_602291; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponentBuildVersions
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602306 = newJObject()
  var body_602307 = newJObject()
  add(query_602306, "nextToken", newJString(nextToken))
  if body != nil:
    body_602307 = body
  add(query_602306, "maxResults", newJString(maxResults))
  result = call_602305.call(nil, query_602306, nil, nil, body_602307)

var listComponentBuildVersions* = Call_ListComponentBuildVersions_602291(
    name: "listComponentBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListComponentBuildVersions",
    validator: validate_ListComponentBuildVersions_602292, base: "/",
    url: url_ListComponentBuildVersions_602293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_602308 = ref object of OpenApiRestCall_601389
proc url_ListComponents_602310(protocol: Scheme; host: string; base: string;
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

proc validate_ListComponents_602309(path: JsonNode; query: JsonNode;
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
  var valid_602311 = query.getOrDefault("nextToken")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "nextToken", valid_602311
  var valid_602312 = query.getOrDefault("maxResults")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "maxResults", valid_602312
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
  var valid_602313 = header.getOrDefault("X-Amz-Signature")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Signature", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Content-Sha256", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Date")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Date", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Credential")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Credential", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Security-Token")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Security-Token", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Algorithm")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Algorithm", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-SignedHeaders", valid_602319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_ListComponents_602308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602321, url, valid)

proc call*(call_602322: Call_ListComponents_602308; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponents
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602323 = newJObject()
  var body_602324 = newJObject()
  add(query_602323, "nextToken", newJString(nextToken))
  if body != nil:
    body_602324 = body
  add(query_602323, "maxResults", newJString(maxResults))
  result = call_602322.call(nil, query_602323, nil, nil, body_602324)

var listComponents* = Call_ListComponents_602308(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListComponents", validator: validate_ListComponents_602309, base: "/",
    url: url_ListComponents_602310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionConfigurations_602325 = ref object of OpenApiRestCall_601389
proc url_ListDistributionConfigurations_602327(protocol: Scheme; host: string;
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

proc validate_ListDistributionConfigurations_602326(path: JsonNode;
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
  var valid_602328 = query.getOrDefault("nextToken")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "nextToken", valid_602328
  var valid_602329 = query.getOrDefault("maxResults")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "maxResults", valid_602329
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
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_ListDistributionConfigurations_602325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_ListDistributionConfigurations_602325; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDistributionConfigurations
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602340 = newJObject()
  var body_602341 = newJObject()
  add(query_602340, "nextToken", newJString(nextToken))
  if body != nil:
    body_602341 = body
  add(query_602340, "maxResults", newJString(maxResults))
  result = call_602339.call(nil, query_602340, nil, nil, body_602341)

var listDistributionConfigurations* = Call_ListDistributionConfigurations_602325(
    name: "listDistributionConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListDistributionConfigurations",
    validator: validate_ListDistributionConfigurations_602326, base: "/",
    url: url_ListDistributionConfigurations_602327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageBuildVersions_602342 = ref object of OpenApiRestCall_601389
proc url_ListImageBuildVersions_602344(protocol: Scheme; host: string; base: string;
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

proc validate_ListImageBuildVersions_602343(path: JsonNode; query: JsonNode;
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
  var valid_602345 = query.getOrDefault("nextToken")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "nextToken", valid_602345
  var valid_602346 = query.getOrDefault("maxResults")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "maxResults", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_ListImageBuildVersions_602342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602355, url, valid)

proc call*(call_602356: Call_ListImageBuildVersions_602342; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageBuildVersions
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602357 = newJObject()
  var body_602358 = newJObject()
  add(query_602357, "nextToken", newJString(nextToken))
  if body != nil:
    body_602358 = body
  add(query_602357, "maxResults", newJString(maxResults))
  result = call_602356.call(nil, query_602357, nil, nil, body_602358)

var listImageBuildVersions* = Call_ListImageBuildVersions_602342(
    name: "listImageBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageBuildVersions",
    validator: validate_ListImageBuildVersions_602343, base: "/",
    url: url_ListImageBuildVersions_602344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelineImages_602359 = ref object of OpenApiRestCall_601389
proc url_ListImagePipelineImages_602361(protocol: Scheme; host: string; base: string;
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

proc validate_ListImagePipelineImages_602360(path: JsonNode; query: JsonNode;
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
  var valid_602362 = query.getOrDefault("nextToken")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "nextToken", valid_602362
  var valid_602363 = query.getOrDefault("maxResults")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "maxResults", valid_602363
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
  var valid_602364 = header.getOrDefault("X-Amz-Signature")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Signature", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Content-Sha256", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Credential")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Credential", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-SignedHeaders", valid_602370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602372: Call_ListImagePipelineImages_602359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  let valid = call_602372.validator(path, query, header, formData, body)
  let scheme = call_602372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602372.url(scheme.get, call_602372.host, call_602372.base,
                         call_602372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602372, url, valid)

proc call*(call_602373: Call_ListImagePipelineImages_602359; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelineImages
  ##  Returns a list of images created by the specified pipeline. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602374 = newJObject()
  var body_602375 = newJObject()
  add(query_602374, "nextToken", newJString(nextToken))
  if body != nil:
    body_602375 = body
  add(query_602374, "maxResults", newJString(maxResults))
  result = call_602373.call(nil, query_602374, nil, nil, body_602375)

var listImagePipelineImages* = Call_ListImagePipelineImages_602359(
    name: "listImagePipelineImages", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelineImages",
    validator: validate_ListImagePipelineImages_602360, base: "/",
    url: url_ListImagePipelineImages_602361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelines_602376 = ref object of OpenApiRestCall_601389
proc url_ListImagePipelines_602378(protocol: Scheme; host: string; base: string;
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

proc validate_ListImagePipelines_602377(path: JsonNode; query: JsonNode;
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
  var valid_602379 = query.getOrDefault("nextToken")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "nextToken", valid_602379
  var valid_602380 = query.getOrDefault("maxResults")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "maxResults", valid_602380
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
  var valid_602381 = header.getOrDefault("X-Amz-Signature")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Signature", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Content-Sha256", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Date")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Date", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Credential")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Credential", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Security-Token")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Security-Token", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Algorithm")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Algorithm", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-SignedHeaders", valid_602387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_ListImagePipelines_602376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of image pipelines. 
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_ListImagePipelines_602376; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelines
  ## Returns a list of image pipelines. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602391 = newJObject()
  var body_602392 = newJObject()
  add(query_602391, "nextToken", newJString(nextToken))
  if body != nil:
    body_602392 = body
  add(query_602391, "maxResults", newJString(maxResults))
  result = call_602390.call(nil, query_602391, nil, nil, body_602392)

var listImagePipelines* = Call_ListImagePipelines_602376(
    name: "listImagePipelines", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelines",
    validator: validate_ListImagePipelines_602377, base: "/",
    url: url_ListImagePipelines_602378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageRecipes_602393 = ref object of OpenApiRestCall_601389
proc url_ListImageRecipes_602395(protocol: Scheme; host: string; base: string;
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

proc validate_ListImageRecipes_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = query.getOrDefault("nextToken")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "nextToken", valid_602396
  var valid_602397 = query.getOrDefault("maxResults")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "maxResults", valid_602397
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
  var valid_602398 = header.getOrDefault("X-Amz-Signature")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Signature", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Content-Sha256", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Date")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Date", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Credential")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Credential", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Security-Token")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Security-Token", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Algorithm")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Algorithm", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-SignedHeaders", valid_602404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602406: Call_ListImageRecipes_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of image recipes. 
  ## 
  let valid = call_602406.validator(path, query, header, formData, body)
  let scheme = call_602406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602406.url(scheme.get, call_602406.host, call_602406.base,
                         call_602406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602406, url, valid)

proc call*(call_602407: Call_ListImageRecipes_602393; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageRecipes
  ##  Returns a list of image recipes. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602408 = newJObject()
  var body_602409 = newJObject()
  add(query_602408, "nextToken", newJString(nextToken))
  if body != nil:
    body_602409 = body
  add(query_602408, "maxResults", newJString(maxResults))
  result = call_602407.call(nil, query_602408, nil, nil, body_602409)

var listImageRecipes* = Call_ListImageRecipes_602393(name: "listImageRecipes",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListImageRecipes", validator: validate_ListImageRecipes_602394,
    base: "/", url: url_ListImageRecipes_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_602410 = ref object of OpenApiRestCall_601389
proc url_ListImages_602412(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListImages_602411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602413 = query.getOrDefault("nextToken")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "nextToken", valid_602413
  var valid_602414 = query.getOrDefault("maxResults")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "maxResults", valid_602414
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
  var valid_602415 = header.getOrDefault("X-Amz-Signature")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Signature", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Content-Sha256", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Date")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Date", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Credential")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Credential", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Security-Token")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Security-Token", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Algorithm")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Algorithm", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-SignedHeaders", valid_602421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602423: Call_ListImages_602410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  let valid = call_602423.validator(path, query, header, formData, body)
  let scheme = call_602423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602423.url(scheme.get, call_602423.host, call_602423.base,
                         call_602423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602423, url, valid)

proc call*(call_602424: Call_ListImages_602410; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ##  Returns the list of image build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602425 = newJObject()
  var body_602426 = newJObject()
  add(query_602425, "nextToken", newJString(nextToken))
  if body != nil:
    body_602426 = body
  add(query_602425, "maxResults", newJString(maxResults))
  result = call_602424.call(nil, query_602425, nil, nil, body_602426)

var listImages* = Call_ListImages_602410(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "imagebuilder.amazonaws.com",
                                      route: "/ListImages",
                                      validator: validate_ListImages_602411,
                                      base: "/", url: url_ListImages_602412,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInfrastructureConfigurations_602427 = ref object of OpenApiRestCall_601389
proc url_ListInfrastructureConfigurations_602429(protocol: Scheme; host: string;
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

proc validate_ListInfrastructureConfigurations_602428(path: JsonNode;
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
  var valid_602430 = query.getOrDefault("nextToken")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "nextToken", valid_602430
  var valid_602431 = query.getOrDefault("maxResults")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "maxResults", valid_602431
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
  var valid_602432 = header.getOrDefault("X-Amz-Signature")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Signature", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Content-Sha256", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Date")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Date", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Credential")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Credential", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Security-Token")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Security-Token", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Algorithm")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Algorithm", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-SignedHeaders", valid_602438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602440: Call_ListInfrastructureConfigurations_602427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of infrastructure configurations. 
  ## 
  let valid = call_602440.validator(path, query, header, formData, body)
  let scheme = call_602440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602440.url(scheme.get, call_602440.host, call_602440.base,
                         call_602440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602440, url, valid)

proc call*(call_602441: Call_ListInfrastructureConfigurations_602427;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listInfrastructureConfigurations
  ##  Returns a list of infrastructure configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602442 = newJObject()
  var body_602443 = newJObject()
  add(query_602442, "nextToken", newJString(nextToken))
  if body != nil:
    body_602443 = body
  add(query_602442, "maxResults", newJString(maxResults))
  result = call_602441.call(nil, query_602442, nil, nil, body_602443)

var listInfrastructureConfigurations* = Call_ListInfrastructureConfigurations_602427(
    name: "listInfrastructureConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListInfrastructureConfigurations",
    validator: validate_ListInfrastructureConfigurations_602428, base: "/",
    url: url_ListInfrastructureConfigurations_602429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602472 = ref object of OpenApiRestCall_601389
proc url_TagResource_602474(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602475 = path.getOrDefault("resourceArn")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "resourceArn", valid_602475
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
  var valid_602476 = header.getOrDefault("X-Amz-Signature")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Signature", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Content-Sha256", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Date")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Date", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Credential")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Credential", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Security-Token")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Security-Token", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Algorithm")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Algorithm", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-SignedHeaders", valid_602482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602484: Call_TagResource_602472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Adds a tag to a resource. 
  ## 
  let valid = call_602484.validator(path, query, header, formData, body)
  let scheme = call_602484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602484.url(scheme.get, call_602484.host, call_602484.base,
                         call_602484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602484, url, valid)

proc call*(call_602485: Call_TagResource_602472; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Adds a tag to a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to tag. 
  ##   body: JObject (required)
  var path_602486 = newJObject()
  var body_602487 = newJObject()
  add(path_602486, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602487 = body
  result = call_602485.call(path_602486, nil, nil, nil, body_602487)

var tagResource* = Call_TagResource_602472(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602473,
                                        base: "/", url: url_TagResource_602474,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602444 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602446(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602445(path: JsonNode; query: JsonNode;
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
  var valid_602461 = path.getOrDefault("resourceArn")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "resourceArn", valid_602461
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
  var valid_602462 = header.getOrDefault("X-Amz-Signature")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Signature", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Content-Sha256", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Date")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Date", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Security-Token")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Security-Token", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Algorithm")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Algorithm", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-SignedHeaders", valid_602468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602469: Call_ListTagsForResource_602444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of tags for the specified resource. 
  ## 
  let valid = call_602469.validator(path, query, header, formData, body)
  let scheme = call_602469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602469.url(scheme.get, call_602469.host, call_602469.base,
                         call_602469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602469, url, valid)

proc call*(call_602470: Call_ListTagsForResource_602444; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  Returns the list of tags for the specified resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you wish to retrieve. 
  var path_602471 = newJObject()
  add(path_602471, "resourceArn", newJString(resourceArn))
  result = call_602470.call(path_602471, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602444(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602445, base: "/",
    url: url_ListTagsForResource_602446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComponentPolicy_602488 = ref object of OpenApiRestCall_601389
proc url_PutComponentPolicy_602490(protocol: Scheme; host: string; base: string;
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

proc validate_PutComponentPolicy_602489(path: JsonNode; query: JsonNode;
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
  var valid_602491 = header.getOrDefault("X-Amz-Signature")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Signature", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Content-Sha256", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Date")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Date", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Credential")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Credential", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Security-Token")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Security-Token", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Algorithm")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Algorithm", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-SignedHeaders", valid_602497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602499: Call_PutComponentPolicy_602488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to a component. 
  ## 
  let valid = call_602499.validator(path, query, header, formData, body)
  let scheme = call_602499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602499.url(scheme.get, call_602499.host, call_602499.base,
                         call_602499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602499, url, valid)

proc call*(call_602500: Call_PutComponentPolicy_602488; body: JsonNode): Recallable =
  ## putComponentPolicy
  ##  Applies a policy to a component. 
  ##   body: JObject (required)
  var body_602501 = newJObject()
  if body != nil:
    body_602501 = body
  result = call_602500.call(nil, nil, nil, nil, body_602501)

var putComponentPolicy* = Call_PutComponentPolicy_602488(
    name: "putComponentPolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutComponentPolicy",
    validator: validate_PutComponentPolicy_602489, base: "/",
    url: url_PutComponentPolicy_602490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImagePolicy_602502 = ref object of OpenApiRestCall_601389
proc url_PutImagePolicy_602504(protocol: Scheme; host: string; base: string;
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

proc validate_PutImagePolicy_602503(path: JsonNode; query: JsonNode;
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
  var valid_602505 = header.getOrDefault("X-Amz-Signature")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Signature", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Content-Sha256", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Date")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Date", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Credential")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Credential", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Security-Token")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Security-Token", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Algorithm")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Algorithm", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-SignedHeaders", valid_602511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602513: Call_PutImagePolicy_602502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image. 
  ## 
  let valid = call_602513.validator(path, query, header, formData, body)
  let scheme = call_602513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602513.url(scheme.get, call_602513.host, call_602513.base,
                         call_602513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602513, url, valid)

proc call*(call_602514: Call_PutImagePolicy_602502; body: JsonNode): Recallable =
  ## putImagePolicy
  ##  Applies a policy to an image. 
  ##   body: JObject (required)
  var body_602515 = newJObject()
  if body != nil:
    body_602515 = body
  result = call_602514.call(nil, nil, nil, nil, body_602515)

var putImagePolicy* = Call_PutImagePolicy_602502(name: "putImagePolicy",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/PutImagePolicy", validator: validate_PutImagePolicy_602503, base: "/",
    url: url_PutImagePolicy_602504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageRecipePolicy_602516 = ref object of OpenApiRestCall_601389
proc url_PutImageRecipePolicy_602518(protocol: Scheme; host: string; base: string;
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

proc validate_PutImageRecipePolicy_602517(path: JsonNode; query: JsonNode;
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
  var valid_602519 = header.getOrDefault("X-Amz-Signature")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Signature", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Content-Sha256", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Date")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Date", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Credential")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Credential", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Security-Token")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Security-Token", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Algorithm")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Algorithm", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-SignedHeaders", valid_602525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602527: Call_PutImageRecipePolicy_602516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image recipe. 
  ## 
  let valid = call_602527.validator(path, query, header, formData, body)
  let scheme = call_602527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602527.url(scheme.get, call_602527.host, call_602527.base,
                         call_602527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602527, url, valid)

proc call*(call_602528: Call_PutImageRecipePolicy_602516; body: JsonNode): Recallable =
  ## putImageRecipePolicy
  ##  Applies a policy to an image recipe. 
  ##   body: JObject (required)
  var body_602529 = newJObject()
  if body != nil:
    body_602529 = body
  result = call_602528.call(nil, nil, nil, nil, body_602529)

var putImageRecipePolicy* = Call_PutImageRecipePolicy_602516(
    name: "putImageRecipePolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutImageRecipePolicy",
    validator: validate_PutImageRecipePolicy_602517, base: "/",
    url: url_PutImageRecipePolicy_602518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImagePipelineExecution_602530 = ref object of OpenApiRestCall_601389
proc url_StartImagePipelineExecution_602532(protocol: Scheme; host: string;
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

proc validate_StartImagePipelineExecution_602531(path: JsonNode; query: JsonNode;
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
  var valid_602533 = header.getOrDefault("X-Amz-Signature")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Signature", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Content-Sha256", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Date")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Date", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Credential")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Credential", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Security-Token")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Security-Token", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Algorithm")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Algorithm", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-SignedHeaders", valid_602539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602541: Call_StartImagePipelineExecution_602530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  let valid = call_602541.validator(path, query, header, formData, body)
  let scheme = call_602541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602541.url(scheme.get, call_602541.host, call_602541.base,
                         call_602541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602541, url, valid)

proc call*(call_602542: Call_StartImagePipelineExecution_602530; body: JsonNode): Recallable =
  ## startImagePipelineExecution
  ##  Manually triggers a pipeline to create an image. 
  ##   body: JObject (required)
  var body_602543 = newJObject()
  if body != nil:
    body_602543 = body
  result = call_602542.call(nil, nil, nil, nil, body_602543)

var startImagePipelineExecution* = Call_StartImagePipelineExecution_602530(
    name: "startImagePipelineExecution", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/StartImagePipelineExecution",
    validator: validate_StartImagePipelineExecution_602531, base: "/",
    url: url_StartImagePipelineExecution_602532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602544 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602546(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602547 = path.getOrDefault("resourceArn")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = nil)
  if valid_602547 != nil:
    section.add "resourceArn", valid_602547
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602548 = query.getOrDefault("tagKeys")
  valid_602548 = validateParameter(valid_602548, JArray, required = true, default = nil)
  if valid_602548 != nil:
    section.add "tagKeys", valid_602548
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
  var valid_602549 = header.getOrDefault("X-Amz-Signature")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Signature", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Content-Sha256", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Date")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Date", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Credential")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Credential", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Security-Token")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Security-Token", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Algorithm")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Algorithm", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-SignedHeaders", valid_602555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602556: Call_UntagResource_602544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Removes a tag from a resource. 
  ## 
  let valid = call_602556.validator(path, query, header, formData, body)
  let scheme = call_602556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602556.url(scheme.get, call_602556.host, call_602556.base,
                         call_602556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602556, url, valid)

proc call*(call_602557: Call_UntagResource_602544; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Removes a tag from a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to untag. 
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  var path_602558 = newJObject()
  var query_602559 = newJObject()
  add(path_602558, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602559.add "tagKeys", tagKeys
  result = call_602557.call(path_602558, query_602559, nil, nil, nil)

var untagResource* = Call_UntagResource_602544(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602545,
    base: "/", url: url_UntagResource_602546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistributionConfiguration_602560 = ref object of OpenApiRestCall_601389
proc url_UpdateDistributionConfiguration_602562(protocol: Scheme; host: string;
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

proc validate_UpdateDistributionConfiguration_602561(path: JsonNode;
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
  var valid_602563 = header.getOrDefault("X-Amz-Signature")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Signature", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Content-Sha256", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Date")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Date", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Credential")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Credential", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Security-Token")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Security-Token", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Algorithm")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Algorithm", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-SignedHeaders", valid_602569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602571: Call_UpdateDistributionConfiguration_602560;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_602571.validator(path, query, header, formData, body)
  let scheme = call_602571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602571.url(scheme.get, call_602571.host, call_602571.base,
                         call_602571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602571, url, valid)

proc call*(call_602572: Call_UpdateDistributionConfiguration_602560; body: JsonNode): Recallable =
  ## updateDistributionConfiguration
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_602573 = newJObject()
  if body != nil:
    body_602573 = body
  result = call_602572.call(nil, nil, nil, nil, body_602573)

var updateDistributionConfiguration* = Call_UpdateDistributionConfiguration_602560(
    name: "updateDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateDistributionConfiguration",
    validator: validate_UpdateDistributionConfiguration_602561, base: "/",
    url: url_UpdateDistributionConfiguration_602562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePipeline_602574 = ref object of OpenApiRestCall_601389
proc url_UpdateImagePipeline_602576(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateImagePipeline_602575(path: JsonNode; query: JsonNode;
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
  var valid_602577 = header.getOrDefault("X-Amz-Signature")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Signature", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Content-Sha256", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Security-Token")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Security-Token", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-SignedHeaders", valid_602583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_UpdateImagePipeline_602574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_UpdateImagePipeline_602574; body: JsonNode): Recallable =
  ## updateImagePipeline
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_602587 = newJObject()
  if body != nil:
    body_602587 = body
  result = call_602586.call(nil, nil, nil, nil, body_602587)

var updateImagePipeline* = Call_UpdateImagePipeline_602574(
    name: "updateImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateImagePipeline",
    validator: validate_UpdateImagePipeline_602575, base: "/",
    url: url_UpdateImagePipeline_602576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInfrastructureConfiguration_602588 = ref object of OpenApiRestCall_601389
proc url_UpdateInfrastructureConfiguration_602590(protocol: Scheme; host: string;
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

proc validate_UpdateInfrastructureConfiguration_602589(path: JsonNode;
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
  var valid_602591 = header.getOrDefault("X-Amz-Signature")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Signature", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Content-Sha256", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Date")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Date", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Credential")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Credential", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Security-Token")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Security-Token", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Algorithm")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Algorithm", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-SignedHeaders", valid_602597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602599: Call_UpdateInfrastructureConfiguration_602588;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_602599.validator(path, query, header, formData, body)
  let scheme = call_602599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602599.url(scheme.get, call_602599.host, call_602599.base,
                         call_602599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602599, url, valid)

proc call*(call_602600: Call_UpdateInfrastructureConfiguration_602588;
          body: JsonNode): Recallable =
  ## updateInfrastructureConfiguration
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_602601 = newJObject()
  if body != nil:
    body_602601 = body
  result = call_602600.call(nil, nil, nil, nil, body_602601)

var updateInfrastructureConfiguration* = Call_UpdateInfrastructureConfiguration_602588(
    name: "updateInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateInfrastructureConfiguration",
    validator: validate_UpdateInfrastructureConfiguration_602589, base: "/",
    url: url_UpdateInfrastructureConfiguration_602590,
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
