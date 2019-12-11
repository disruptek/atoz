
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CancelImageCreation_597727 = ref object of OpenApiRestCall_597389
proc url_CancelImageCreation_597729(protocol: Scheme; host: string; base: string;
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

proc validate_CancelImageCreation_597728(path: JsonNode; query: JsonNode;
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
  var valid_597841 = header.getOrDefault("X-Amz-Signature")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "X-Amz-Signature", valid_597841
  var valid_597842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "X-Amz-Content-Sha256", valid_597842
  var valid_597843 = header.getOrDefault("X-Amz-Date")
  valid_597843 = validateParameter(valid_597843, JString, required = false,
                                 default = nil)
  if valid_597843 != nil:
    section.add "X-Amz-Date", valid_597843
  var valid_597844 = header.getOrDefault("X-Amz-Credential")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-Credential", valid_597844
  var valid_597845 = header.getOrDefault("X-Amz-Security-Token")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "X-Amz-Security-Token", valid_597845
  var valid_597846 = header.getOrDefault("X-Amz-Algorithm")
  valid_597846 = validateParameter(valid_597846, JString, required = false,
                                 default = nil)
  if valid_597846 != nil:
    section.add "X-Amz-Algorithm", valid_597846
  var valid_597847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-SignedHeaders", valid_597847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597871: Call_CancelImageCreation_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ## 
  let valid = call_597871.validator(path, query, header, formData, body)
  let scheme = call_597871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597871.url(scheme.get, call_597871.host, call_597871.base,
                         call_597871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597871, url, valid)

proc call*(call_597942: Call_CancelImageCreation_597727; body: JsonNode): Recallable =
  ## cancelImageCreation
  ## CancelImageCreation cancels the creation of Image. This operation may only be used on images in a non-terminal state.
  ##   body: JObject (required)
  var body_597943 = newJObject()
  if body != nil:
    body_597943 = body
  result = call_597942.call(nil, nil, nil, nil, body_597943)

var cancelImageCreation* = Call_CancelImageCreation_597727(
    name: "cancelImageCreation", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CancelImageCreation",
    validator: validate_CancelImageCreation_597728, base: "/",
    url: url_CancelImageCreation_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_597982 = ref object of OpenApiRestCall_597389
proc url_CreateComponent_597984(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComponent_597983(path: JsonNode; query: JsonNode;
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
  var valid_597985 = header.getOrDefault("X-Amz-Signature")
  valid_597985 = validateParameter(valid_597985, JString, required = false,
                                 default = nil)
  if valid_597985 != nil:
    section.add "X-Amz-Signature", valid_597985
  var valid_597986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597986 = validateParameter(valid_597986, JString, required = false,
                                 default = nil)
  if valid_597986 != nil:
    section.add "X-Amz-Content-Sha256", valid_597986
  var valid_597987 = header.getOrDefault("X-Amz-Date")
  valid_597987 = validateParameter(valid_597987, JString, required = false,
                                 default = nil)
  if valid_597987 != nil:
    section.add "X-Amz-Date", valid_597987
  var valid_597988 = header.getOrDefault("X-Amz-Credential")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "X-Amz-Credential", valid_597988
  var valid_597989 = header.getOrDefault("X-Amz-Security-Token")
  valid_597989 = validateParameter(valid_597989, JString, required = false,
                                 default = nil)
  if valid_597989 != nil:
    section.add "X-Amz-Security-Token", valid_597989
  var valid_597990 = header.getOrDefault("X-Amz-Algorithm")
  valid_597990 = validateParameter(valid_597990, JString, required = false,
                                 default = nil)
  if valid_597990 != nil:
    section.add "X-Amz-Algorithm", valid_597990
  var valid_597991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597991 = validateParameter(valid_597991, JString, required = false,
                                 default = nil)
  if valid_597991 != nil:
    section.add "X-Amz-SignedHeaders", valid_597991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597993: Call_CreateComponent_597982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ## 
  let valid = call_597993.validator(path, query, header, formData, body)
  let scheme = call_597993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597993.url(scheme.get, call_597993.host, call_597993.base,
                         call_597993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597993, url, valid)

proc call*(call_597994: Call_CreateComponent_597982; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a new component that can be used to build, validate, test and assess your image.
  ##   body: JObject (required)
  var body_597995 = newJObject()
  if body != nil:
    body_597995 = body
  result = call_597994.call(nil, nil, nil, nil, body_597995)

var createComponent* = Call_CreateComponent_597982(name: "createComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateComponent", validator: validate_CreateComponent_597983,
    base: "/", url: url_CreateComponent_597984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionConfiguration_597996 = ref object of OpenApiRestCall_597389
proc url_CreateDistributionConfiguration_597998(protocol: Scheme; host: string;
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

proc validate_CreateDistributionConfiguration_597997(path: JsonNode;
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
  var valid_597999 = header.getOrDefault("X-Amz-Signature")
  valid_597999 = validateParameter(valid_597999, JString, required = false,
                                 default = nil)
  if valid_597999 != nil:
    section.add "X-Amz-Signature", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Content-Sha256", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Date")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Date", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Credential")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Credential", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Security-Token")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Security-Token", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Algorithm")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Algorithm", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-SignedHeaders", valid_598005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598007: Call_CreateDistributionConfiguration_597996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_598007.validator(path, query, header, formData, body)
  let scheme = call_598007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598007.url(scheme.get, call_598007.host, call_598007.base,
                         call_598007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598007, url, valid)

proc call*(call_598008: Call_CreateDistributionConfiguration_597996; body: JsonNode): Recallable =
  ## createDistributionConfiguration
  ##  Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_598009 = newJObject()
  if body != nil:
    body_598009 = body
  result = call_598008.call(nil, nil, nil, nil, body_598009)

var createDistributionConfiguration* = Call_CreateDistributionConfiguration_597996(
    name: "createDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateDistributionConfiguration",
    validator: validate_CreateDistributionConfiguration_597997, base: "/",
    url: url_CreateDistributionConfiguration_597998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImage_598010 = ref object of OpenApiRestCall_597389
proc url_CreateImage_598012(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImage_598011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598013 = header.getOrDefault("X-Amz-Signature")
  valid_598013 = validateParameter(valid_598013, JString, required = false,
                                 default = nil)
  if valid_598013 != nil:
    section.add "X-Amz-Signature", valid_598013
  var valid_598014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598014 = validateParameter(valid_598014, JString, required = false,
                                 default = nil)
  if valid_598014 != nil:
    section.add "X-Amz-Content-Sha256", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Date")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Date", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Credential")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Credential", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Security-Token")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Security-Token", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Algorithm")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Algorithm", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-SignedHeaders", valid_598019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598021: Call_CreateImage_598010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  let valid = call_598021.validator(path, query, header, formData, body)
  let scheme = call_598021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598021.url(scheme.get, call_598021.host, call_598021.base,
                         call_598021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598021, url, valid)

proc call*(call_598022: Call_CreateImage_598010; body: JsonNode): Recallable =
  ## createImage
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ##   body: JObject (required)
  var body_598023 = newJObject()
  if body != nil:
    body_598023 = body
  result = call_598022.call(nil, nil, nil, nil, body_598023)

var createImage* = Call_CreateImage_598010(name: "createImage",
                                        meth: HttpMethod.HttpPut,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/CreateImage",
                                        validator: validate_CreateImage_598011,
                                        base: "/", url: url_CreateImage_598012,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImagePipeline_598024 = ref object of OpenApiRestCall_597389
proc url_CreateImagePipeline_598026(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImagePipeline_598025(path: JsonNode; query: JsonNode;
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
  var valid_598027 = header.getOrDefault("X-Amz-Signature")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Signature", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-Content-Sha256", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-Date")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-Date", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Credential")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Credential", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Security-Token")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Security-Token", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Algorithm")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Algorithm", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-SignedHeaders", valid_598033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598035: Call_CreateImagePipeline_598024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_598035.validator(path, query, header, formData, body)
  let scheme = call_598035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598035.url(scheme.get, call_598035.host, call_598035.base,
                         call_598035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598035, url, valid)

proc call*(call_598036: Call_CreateImagePipeline_598024; body: JsonNode): Recallable =
  ## createImagePipeline
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_598037 = newJObject()
  if body != nil:
    body_598037 = body
  result = call_598036.call(nil, nil, nil, nil, body_598037)

var createImagePipeline* = Call_CreateImagePipeline_598024(
    name: "createImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImagePipeline",
    validator: validate_CreateImagePipeline_598025, base: "/",
    url: url_CreateImagePipeline_598026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageRecipe_598038 = ref object of OpenApiRestCall_597389
proc url_CreateImageRecipe_598040(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImageRecipe_598039(path: JsonNode; query: JsonNode;
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
  var valid_598041 = header.getOrDefault("X-Amz-Signature")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Signature", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-Content-Sha256", valid_598042
  var valid_598043 = header.getOrDefault("X-Amz-Date")
  valid_598043 = validateParameter(valid_598043, JString, required = false,
                                 default = nil)
  if valid_598043 != nil:
    section.add "X-Amz-Date", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-Credential")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Credential", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Security-Token")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Security-Token", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Algorithm")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Algorithm", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-SignedHeaders", valid_598047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598049: Call_CreateImageRecipe_598038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ## 
  let valid = call_598049.validator(path, query, header, formData, body)
  let scheme = call_598049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598049.url(scheme.get, call_598049.host, call_598049.base,
                         call_598049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598049, url, valid)

proc call*(call_598050: Call_CreateImageRecipe_598038; body: JsonNode): Recallable =
  ## createImageRecipe
  ##  Creates a new image recipe. Image Recipes defines how images are configured, tested and assessed. 
  ##   body: JObject (required)
  var body_598051 = newJObject()
  if body != nil:
    body_598051 = body
  result = call_598050.call(nil, nil, nil, nil, body_598051)

var createImageRecipe* = Call_CreateImageRecipe_598038(name: "createImageRecipe",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateImageRecipe", validator: validate_CreateImageRecipe_598039,
    base: "/", url: url_CreateImageRecipe_598040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInfrastructureConfiguration_598052 = ref object of OpenApiRestCall_597389
proc url_CreateInfrastructureConfiguration_598054(protocol: Scheme; host: string;
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

proc validate_CreateInfrastructureConfiguration_598053(path: JsonNode;
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
  var valid_598055 = header.getOrDefault("X-Amz-Signature")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Signature", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-Content-Sha256", valid_598056
  var valid_598057 = header.getOrDefault("X-Amz-Date")
  valid_598057 = validateParameter(valid_598057, JString, required = false,
                                 default = nil)
  if valid_598057 != nil:
    section.add "X-Amz-Date", valid_598057
  var valid_598058 = header.getOrDefault("X-Amz-Credential")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-Credential", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-Security-Token")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-Security-Token", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Algorithm")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Algorithm", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-SignedHeaders", valid_598061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598063: Call_CreateInfrastructureConfiguration_598052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_598063.validator(path, query, header, formData, body)
  let scheme = call_598063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598063.url(scheme.get, call_598063.host, call_598063.base,
                         call_598063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598063, url, valid)

proc call*(call_598064: Call_CreateInfrastructureConfiguration_598052;
          body: JsonNode): Recallable =
  ## createInfrastructureConfiguration
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_598065 = newJObject()
  if body != nil:
    body_598065 = body
  result = call_598064.call(nil, nil, nil, nil, body_598065)

var createInfrastructureConfiguration* = Call_CreateInfrastructureConfiguration_598052(
    name: "createInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateInfrastructureConfiguration",
    validator: validate_CreateInfrastructureConfiguration_598053, base: "/",
    url: url_CreateInfrastructureConfiguration_598054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_598066 = ref object of OpenApiRestCall_597389
proc url_DeleteComponent_598068(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComponent_598067(path: JsonNode; query: JsonNode;
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
  var valid_598069 = query.getOrDefault("componentBuildVersionArn")
  valid_598069 = validateParameter(valid_598069, JString, required = true,
                                 default = nil)
  if valid_598069 != nil:
    section.add "componentBuildVersionArn", valid_598069
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
  var valid_598070 = header.getOrDefault("X-Amz-Signature")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Signature", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Content-Sha256", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Date")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Date", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-Credential")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Credential", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Security-Token")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Security-Token", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Algorithm")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Algorithm", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-SignedHeaders", valid_598076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598077: Call_DeleteComponent_598066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a component build version. 
  ## 
  let valid = call_598077.validator(path, query, header, formData, body)
  let scheme = call_598077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598077.url(scheme.get, call_598077.host, call_598077.base,
                         call_598077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598077, url, valid)

proc call*(call_598078: Call_DeleteComponent_598066;
          componentBuildVersionArn: string): Recallable =
  ## deleteComponent
  ##  Deletes a component build version. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  var query_598079 = newJObject()
  add(query_598079, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_598078.call(nil, query_598079, nil, nil, nil)

var deleteComponent* = Call_DeleteComponent_598066(name: "deleteComponent",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteComponent#componentBuildVersionArn",
    validator: validate_DeleteComponent_598067, base: "/", url: url_DeleteComponent_598068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistributionConfiguration_598081 = ref object of OpenApiRestCall_597389
proc url_DeleteDistributionConfiguration_598083(protocol: Scheme; host: string;
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

proc validate_DeleteDistributionConfiguration_598082(path: JsonNode;
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
  var valid_598084 = query.getOrDefault("distributionConfigurationArn")
  valid_598084 = validateParameter(valid_598084, JString, required = true,
                                 default = nil)
  if valid_598084 != nil:
    section.add "distributionConfigurationArn", valid_598084
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
  var valid_598085 = header.getOrDefault("X-Amz-Signature")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Signature", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Content-Sha256", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Date")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Date", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-Credential")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-Credential", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-Security-Token")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-Security-Token", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Algorithm")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Algorithm", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-SignedHeaders", valid_598091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598092: Call_DeleteDistributionConfiguration_598081;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes a distribution configuration. 
  ## 
  let valid = call_598092.validator(path, query, header, formData, body)
  let scheme = call_598092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598092.url(scheme.get, call_598092.host, call_598092.base,
                         call_598092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598092, url, valid)

proc call*(call_598093: Call_DeleteDistributionConfiguration_598081;
          distributionConfigurationArn: string): Recallable =
  ## deleteDistributionConfiguration
  ##  Deletes a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  var query_598094 = newJObject()
  add(query_598094, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_598093.call(nil, query_598094, nil, nil, nil)

var deleteDistributionConfiguration* = Call_DeleteDistributionConfiguration_598081(
    name: "deleteDistributionConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteDistributionConfiguration#distributionConfigurationArn",
    validator: validate_DeleteDistributionConfiguration_598082, base: "/",
    url: url_DeleteDistributionConfiguration_598083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_598095 = ref object of OpenApiRestCall_597389
proc url_DeleteImage_598097(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImage_598096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598098 = query.getOrDefault("imageBuildVersionArn")
  valid_598098 = validateParameter(valid_598098, JString, required = true,
                                 default = nil)
  if valid_598098 != nil:
    section.add "imageBuildVersionArn", valid_598098
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
  var valid_598099 = header.getOrDefault("X-Amz-Signature")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "X-Amz-Signature", valid_598099
  var valid_598100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "X-Amz-Content-Sha256", valid_598100
  var valid_598101 = header.getOrDefault("X-Amz-Date")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Date", valid_598101
  var valid_598102 = header.getOrDefault("X-Amz-Credential")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Credential", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Security-Token")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Security-Token", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Algorithm")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Algorithm", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-SignedHeaders", valid_598105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598106: Call_DeleteImage_598095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image. 
  ## 
  let valid = call_598106.validator(path, query, header, formData, body)
  let scheme = call_598106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598106.url(scheme.get, call_598106.host, call_598106.base,
                         call_598106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598106, url, valid)

proc call*(call_598107: Call_DeleteImage_598095; imageBuildVersionArn: string): Recallable =
  ## deleteImage
  ##  Deletes an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  var query_598108 = newJObject()
  add(query_598108, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_598107.call(nil, query_598108, nil, nil, nil)

var deleteImage* = Call_DeleteImage_598095(name: "deleteImage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "imagebuilder.amazonaws.com", route: "/DeleteImage#imageBuildVersionArn",
                                        validator: validate_DeleteImage_598096,
                                        base: "/", url: url_DeleteImage_598097,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePipeline_598109 = ref object of OpenApiRestCall_597389
proc url_DeleteImagePipeline_598111(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImagePipeline_598110(path: JsonNode; query: JsonNode;
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
  var valid_598112 = query.getOrDefault("imagePipelineArn")
  valid_598112 = validateParameter(valid_598112, JString, required = true,
                                 default = nil)
  if valid_598112 != nil:
    section.add "imagePipelineArn", valid_598112
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
  var valid_598113 = header.getOrDefault("X-Amz-Signature")
  valid_598113 = validateParameter(valid_598113, JString, required = false,
                                 default = nil)
  if valid_598113 != nil:
    section.add "X-Amz-Signature", valid_598113
  var valid_598114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-Content-Sha256", valid_598114
  var valid_598115 = header.getOrDefault("X-Amz-Date")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-Date", valid_598115
  var valid_598116 = header.getOrDefault("X-Amz-Credential")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "X-Amz-Credential", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Security-Token")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Security-Token", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-Algorithm")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Algorithm", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-SignedHeaders", valid_598119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598120: Call_DeleteImagePipeline_598109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image pipeline. 
  ## 
  let valid = call_598120.validator(path, query, header, formData, body)
  let scheme = call_598120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598120.url(scheme.get, call_598120.host, call_598120.base,
                         call_598120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598120, url, valid)

proc call*(call_598121: Call_DeleteImagePipeline_598109; imagePipelineArn: string): Recallable =
  ## deleteImagePipeline
  ##  Deletes an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  var query_598122 = newJObject()
  add(query_598122, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_598121.call(nil, query_598122, nil, nil, nil)

var deleteImagePipeline* = Call_DeleteImagePipeline_598109(
    name: "deleteImagePipeline", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImagePipeline#imagePipelineArn",
    validator: validate_DeleteImagePipeline_598110, base: "/",
    url: url_DeleteImagePipeline_598111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageRecipe_598123 = ref object of OpenApiRestCall_597389
proc url_DeleteImageRecipe_598125(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteImageRecipe_598124(path: JsonNode; query: JsonNode;
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
  var valid_598126 = query.getOrDefault("imageRecipeArn")
  valid_598126 = validateParameter(valid_598126, JString, required = true,
                                 default = nil)
  if valid_598126 != nil:
    section.add "imageRecipeArn", valid_598126
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
  var valid_598127 = header.getOrDefault("X-Amz-Signature")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Signature", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Content-Sha256", valid_598128
  var valid_598129 = header.getOrDefault("X-Amz-Date")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "X-Amz-Date", valid_598129
  var valid_598130 = header.getOrDefault("X-Amz-Credential")
  valid_598130 = validateParameter(valid_598130, JString, required = false,
                                 default = nil)
  if valid_598130 != nil:
    section.add "X-Amz-Credential", valid_598130
  var valid_598131 = header.getOrDefault("X-Amz-Security-Token")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "X-Amz-Security-Token", valid_598131
  var valid_598132 = header.getOrDefault("X-Amz-Algorithm")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Algorithm", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-SignedHeaders", valid_598133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598134: Call_DeleteImageRecipe_598123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an image recipe. 
  ## 
  let valid = call_598134.validator(path, query, header, formData, body)
  let scheme = call_598134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598134.url(scheme.get, call_598134.host, call_598134.base,
                         call_598134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598134, url, valid)

proc call*(call_598135: Call_DeleteImageRecipe_598123; imageRecipeArn: string): Recallable =
  ## deleteImageRecipe
  ##  Deletes an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  var query_598136 = newJObject()
  add(query_598136, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_598135.call(nil, query_598136, nil, nil, nil)

var deleteImageRecipe* = Call_DeleteImageRecipe_598123(name: "deleteImageRecipe",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteImageRecipe#imageRecipeArn",
    validator: validate_DeleteImageRecipe_598124, base: "/",
    url: url_DeleteImageRecipe_598125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInfrastructureConfiguration_598137 = ref object of OpenApiRestCall_597389
proc url_DeleteInfrastructureConfiguration_598139(protocol: Scheme; host: string;
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

proc validate_DeleteInfrastructureConfiguration_598138(path: JsonNode;
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
  var valid_598140 = query.getOrDefault("infrastructureConfigurationArn")
  valid_598140 = validateParameter(valid_598140, JString, required = true,
                                 default = nil)
  if valid_598140 != nil:
    section.add "infrastructureConfigurationArn", valid_598140
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
  var valid_598141 = header.getOrDefault("X-Amz-Signature")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-Signature", valid_598141
  var valid_598142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Content-Sha256", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-Date")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Date", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Credential")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Credential", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Security-Token")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Security-Token", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Algorithm")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Algorithm", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-SignedHeaders", valid_598147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598148: Call_DeleteInfrastructureConfiguration_598137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Deletes an infrastructure configuration. 
  ## 
  let valid = call_598148.validator(path, query, header, formData, body)
  let scheme = call_598148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598148.url(scheme.get, call_598148.host, call_598148.base,
                         call_598148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598148, url, valid)

proc call*(call_598149: Call_DeleteInfrastructureConfiguration_598137;
          infrastructureConfigurationArn: string): Recallable =
  ## deleteInfrastructureConfiguration
  ##  Deletes an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  var query_598150 = newJObject()
  add(query_598150, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_598149.call(nil, query_598150, nil, nil, nil)

var deleteInfrastructureConfiguration* = Call_DeleteInfrastructureConfiguration_598137(
    name: "deleteInfrastructureConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_DeleteInfrastructureConfiguration_598138, base: "/",
    url: url_DeleteInfrastructureConfiguration_598139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponent_598151 = ref object of OpenApiRestCall_597389
proc url_GetComponent_598153(protocol: Scheme; host: string; base: string;
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

proc validate_GetComponent_598152(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598154 = query.getOrDefault("componentBuildVersionArn")
  valid_598154 = validateParameter(valid_598154, JString, required = true,
                                 default = nil)
  if valid_598154 != nil:
    section.add "componentBuildVersionArn", valid_598154
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
  var valid_598155 = header.getOrDefault("X-Amz-Signature")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Signature", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-Content-Sha256", valid_598156
  var valid_598157 = header.getOrDefault("X-Amz-Date")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Date", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-Credential")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Credential", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Security-Token")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Security-Token", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Algorithm")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Algorithm", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-SignedHeaders", valid_598161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598162: Call_GetComponent_598151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component object. 
  ## 
  let valid = call_598162.validator(path, query, header, formData, body)
  let scheme = call_598162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598162.url(scheme.get, call_598162.host, call_598162.base,
                         call_598162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598162, url, valid)

proc call*(call_598163: Call_GetComponent_598151; componentBuildVersionArn: string): Recallable =
  ## getComponent
  ##  Gets a component object. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you wish to retrieve. 
  var query_598164 = newJObject()
  add(query_598164, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_598163.call(nil, query_598164, nil, nil, nil)

var getComponent* = Call_GetComponent_598151(name: "getComponent",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetComponent#componentBuildVersionArn",
    validator: validate_GetComponent_598152, base: "/", url: url_GetComponent_598153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponentPolicy_598165 = ref object of OpenApiRestCall_597389
proc url_GetComponentPolicy_598167(protocol: Scheme; host: string; base: string;
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

proc validate_GetComponentPolicy_598166(path: JsonNode; query: JsonNode;
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
  var valid_598168 = query.getOrDefault("componentArn")
  valid_598168 = validateParameter(valid_598168, JString, required = true,
                                 default = nil)
  if valid_598168 != nil:
    section.add "componentArn", valid_598168
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
  var valid_598169 = header.getOrDefault("X-Amz-Signature")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Signature", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-Content-Sha256", valid_598170
  var valid_598171 = header.getOrDefault("X-Amz-Date")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-Date", valid_598171
  var valid_598172 = header.getOrDefault("X-Amz-Credential")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "X-Amz-Credential", valid_598172
  var valid_598173 = header.getOrDefault("X-Amz-Security-Token")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-Security-Token", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Algorithm")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Algorithm", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-SignedHeaders", valid_598175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598176: Call_GetComponentPolicy_598165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a component policy. 
  ## 
  let valid = call_598176.validator(path, query, header, formData, body)
  let scheme = call_598176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598176.url(scheme.get, call_598176.host, call_598176.base,
                         call_598176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598176, url, valid)

proc call*(call_598177: Call_GetComponentPolicy_598165; componentArn: string): Recallable =
  ## getComponentPolicy
  ##  Gets a component policy. 
  ##   componentArn: string (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you wish to retrieve. 
  var query_598178 = newJObject()
  add(query_598178, "componentArn", newJString(componentArn))
  result = call_598177.call(nil, query_598178, nil, nil, nil)

var getComponentPolicy* = Call_GetComponentPolicy_598165(
    name: "getComponentPolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/GetComponentPolicy#componentArn",
    validator: validate_GetComponentPolicy_598166, base: "/",
    url: url_GetComponentPolicy_598167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfiguration_598179 = ref object of OpenApiRestCall_597389
proc url_GetDistributionConfiguration_598181(protocol: Scheme; host: string;
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

proc validate_GetDistributionConfiguration_598180(path: JsonNode; query: JsonNode;
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
  var valid_598182 = query.getOrDefault("distributionConfigurationArn")
  valid_598182 = validateParameter(valid_598182, JString, required = true,
                                 default = nil)
  if valid_598182 != nil:
    section.add "distributionConfigurationArn", valid_598182
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
  var valid_598183 = header.getOrDefault("X-Amz-Signature")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Signature", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Content-Sha256", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-Date")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-Date", valid_598185
  var valid_598186 = header.getOrDefault("X-Amz-Credential")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "X-Amz-Credential", valid_598186
  var valid_598187 = header.getOrDefault("X-Amz-Security-Token")
  valid_598187 = validateParameter(valid_598187, JString, required = false,
                                 default = nil)
  if valid_598187 != nil:
    section.add "X-Amz-Security-Token", valid_598187
  var valid_598188 = header.getOrDefault("X-Amz-Algorithm")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "X-Amz-Algorithm", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-SignedHeaders", valid_598189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598190: Call_GetDistributionConfiguration_598179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a distribution configuration. 
  ## 
  let valid = call_598190.validator(path, query, header, formData, body)
  let scheme = call_598190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598190.url(scheme.get, call_598190.host, call_598190.base,
                         call_598190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598190, url, valid)

proc call*(call_598191: Call_GetDistributionConfiguration_598179;
          distributionConfigurationArn: string): Recallable =
  ## getDistributionConfiguration
  ##  Gets a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you wish to retrieve. 
  var query_598192 = newJObject()
  add(query_598192, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_598191.call(nil, query_598192, nil, nil, nil)

var getDistributionConfiguration* = Call_GetDistributionConfiguration_598179(
    name: "getDistributionConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetDistributionConfiguration#distributionConfigurationArn",
    validator: validate_GetDistributionConfiguration_598180, base: "/",
    url: url_GetDistributionConfiguration_598181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImage_598193 = ref object of OpenApiRestCall_597389
proc url_GetImage_598195(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetImage_598194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598196 = query.getOrDefault("imageBuildVersionArn")
  valid_598196 = validateParameter(valid_598196, JString, required = true,
                                 default = nil)
  if valid_598196 != nil:
    section.add "imageBuildVersionArn", valid_598196
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
  var valid_598197 = header.getOrDefault("X-Amz-Signature")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Signature", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Content-Sha256", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Date")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Date", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Credential")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Credential", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-Security-Token")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-Security-Token", valid_598201
  var valid_598202 = header.getOrDefault("X-Amz-Algorithm")
  valid_598202 = validateParameter(valid_598202, JString, required = false,
                                 default = nil)
  if valid_598202 != nil:
    section.add "X-Amz-Algorithm", valid_598202
  var valid_598203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "X-Amz-SignedHeaders", valid_598203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598204: Call_GetImage_598193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image. 
  ## 
  let valid = call_598204.validator(path, query, header, formData, body)
  let scheme = call_598204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598204.url(scheme.get, call_598204.host, call_598204.base,
                         call_598204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598204, url, valid)

proc call*(call_598205: Call_GetImage_598193; imageBuildVersionArn: string): Recallable =
  ## getImage
  ##  Gets an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you wish to retrieve. 
  var query_598206 = newJObject()
  add(query_598206, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_598205.call(nil, query_598206, nil, nil, nil)

var getImage* = Call_GetImage_598193(name: "getImage", meth: HttpMethod.HttpGet,
                                  host: "imagebuilder.amazonaws.com",
                                  route: "/GetImage#imageBuildVersionArn",
                                  validator: validate_GetImage_598194, base: "/",
                                  url: url_GetImage_598195,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePipeline_598207 = ref object of OpenApiRestCall_597389
proc url_GetImagePipeline_598209(protocol: Scheme; host: string; base: string;
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

proc validate_GetImagePipeline_598208(path: JsonNode; query: JsonNode;
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
  var valid_598210 = query.getOrDefault("imagePipelineArn")
  valid_598210 = validateParameter(valid_598210, JString, required = true,
                                 default = nil)
  if valid_598210 != nil:
    section.add "imagePipelineArn", valid_598210
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
  var valid_598211 = header.getOrDefault("X-Amz-Signature")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Signature", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Content-Sha256", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Date")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Date", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Credential")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Credential", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Security-Token")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Security-Token", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-Algorithm")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-Algorithm", valid_598216
  var valid_598217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598217 = validateParameter(valid_598217, JString, required = false,
                                 default = nil)
  if valid_598217 != nil:
    section.add "X-Amz-SignedHeaders", valid_598217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598218: Call_GetImagePipeline_598207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image pipeline. 
  ## 
  let valid = call_598218.validator(path, query, header, formData, body)
  let scheme = call_598218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598218.url(scheme.get, call_598218.host, call_598218.base,
                         call_598218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598218, url, valid)

proc call*(call_598219: Call_GetImagePipeline_598207; imagePipelineArn: string): Recallable =
  ## getImagePipeline
  ##  Gets an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you wish to retrieve. 
  var query_598220 = newJObject()
  add(query_598220, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_598219.call(nil, query_598220, nil, nil, nil)

var getImagePipeline* = Call_GetImagePipeline_598207(name: "getImagePipeline",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePipeline#imagePipelineArn",
    validator: validate_GetImagePipeline_598208, base: "/",
    url: url_GetImagePipeline_598209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePolicy_598221 = ref object of OpenApiRestCall_597389
proc url_GetImagePolicy_598223(protocol: Scheme; host: string; base: string;
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

proc validate_GetImagePolicy_598222(path: JsonNode; query: JsonNode;
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
  var valid_598224 = query.getOrDefault("imageArn")
  valid_598224 = validateParameter(valid_598224, JString, required = true,
                                 default = nil)
  if valid_598224 != nil:
    section.add "imageArn", valid_598224
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
  var valid_598225 = header.getOrDefault("X-Amz-Signature")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Signature", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Content-Sha256", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Date")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Date", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Credential")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Credential", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Security-Token")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Security-Token", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Algorithm")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Algorithm", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-SignedHeaders", valid_598231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598232: Call_GetImagePolicy_598221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image policy. 
  ## 
  let valid = call_598232.validator(path, query, header, formData, body)
  let scheme = call_598232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598232.url(scheme.get, call_598232.host, call_598232.base,
                         call_598232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598232, url, valid)

proc call*(call_598233: Call_GetImagePolicy_598221; imageArn: string): Recallable =
  ## getImagePolicy
  ##  Gets an image policy. 
  ##   imageArn: string (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you wish to retrieve. 
  var query_598234 = newJObject()
  add(query_598234, "imageArn", newJString(imageArn))
  result = call_598233.call(nil, query_598234, nil, nil, nil)

var getImagePolicy* = Call_GetImagePolicy_598221(name: "getImagePolicy",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePolicy#imageArn", validator: validate_GetImagePolicy_598222,
    base: "/", url: url_GetImagePolicy_598223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipe_598235 = ref object of OpenApiRestCall_597389
proc url_GetImageRecipe_598237(protocol: Scheme; host: string; base: string;
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

proc validate_GetImageRecipe_598236(path: JsonNode; query: JsonNode;
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
  var valid_598238 = query.getOrDefault("imageRecipeArn")
  valid_598238 = validateParameter(valid_598238, JString, required = true,
                                 default = nil)
  if valid_598238 != nil:
    section.add "imageRecipeArn", valid_598238
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
  var valid_598239 = header.getOrDefault("X-Amz-Signature")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-Signature", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Content-Sha256", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Date")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Date", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Credential")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Credential", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Security-Token")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Security-Token", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Algorithm")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Algorithm", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-SignedHeaders", valid_598245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598246: Call_GetImageRecipe_598235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe. 
  ## 
  let valid = call_598246.validator(path, query, header, formData, body)
  let scheme = call_598246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598246.url(scheme.get, call_598246.host, call_598246.base,
                         call_598246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598246, url, valid)

proc call*(call_598247: Call_GetImageRecipe_598235; imageRecipeArn: string): Recallable =
  ## getImageRecipe
  ##  Gets an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you wish to retrieve. 
  var query_598248 = newJObject()
  add(query_598248, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_598247.call(nil, query_598248, nil, nil, nil)

var getImageRecipe* = Call_GetImageRecipe_598235(name: "getImageRecipe",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipe#imageRecipeArn", validator: validate_GetImageRecipe_598236,
    base: "/", url: url_GetImageRecipe_598237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipePolicy_598249 = ref object of OpenApiRestCall_597389
proc url_GetImageRecipePolicy_598251(protocol: Scheme; host: string; base: string;
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

proc validate_GetImageRecipePolicy_598250(path: JsonNode; query: JsonNode;
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
  var valid_598252 = query.getOrDefault("imageRecipeArn")
  valid_598252 = validateParameter(valid_598252, JString, required = true,
                                 default = nil)
  if valid_598252 != nil:
    section.add "imageRecipeArn", valid_598252
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
  var valid_598253 = header.getOrDefault("X-Amz-Signature")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Signature", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-Content-Sha256", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Date")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Date", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-Credential")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-Credential", valid_598256
  var valid_598257 = header.getOrDefault("X-Amz-Security-Token")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Security-Token", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Algorithm")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Algorithm", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-SignedHeaders", valid_598259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598260: Call_GetImageRecipePolicy_598249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets an image recipe policy. 
  ## 
  let valid = call_598260.validator(path, query, header, formData, body)
  let scheme = call_598260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598260.url(scheme.get, call_598260.host, call_598260.base,
                         call_598260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598260, url, valid)

proc call*(call_598261: Call_GetImageRecipePolicy_598249; imageRecipeArn: string): Recallable =
  ## getImageRecipePolicy
  ##  Gets an image recipe policy. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you wish to retrieve. 
  var query_598262 = newJObject()
  add(query_598262, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_598261.call(nil, query_598262, nil, nil, nil)

var getImageRecipePolicy* = Call_GetImageRecipePolicy_598249(
    name: "getImageRecipePolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipePolicy#imageRecipeArn",
    validator: validate_GetImageRecipePolicy_598250, base: "/",
    url: url_GetImageRecipePolicy_598251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInfrastructureConfiguration_598263 = ref object of OpenApiRestCall_597389
proc url_GetInfrastructureConfiguration_598265(protocol: Scheme; host: string;
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

proc validate_GetInfrastructureConfiguration_598264(path: JsonNode;
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
  var valid_598266 = query.getOrDefault("infrastructureConfigurationArn")
  valid_598266 = validateParameter(valid_598266, JString, required = true,
                                 default = nil)
  if valid_598266 != nil:
    section.add "infrastructureConfigurationArn", valid_598266
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
  var valid_598267 = header.getOrDefault("X-Amz-Signature")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Signature", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Content-Sha256", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Date")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Date", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Credential")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Credential", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Security-Token")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Security-Token", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Algorithm")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Algorithm", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-SignedHeaders", valid_598273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598274: Call_GetInfrastructureConfiguration_598263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a infrastructure configuration. 
  ## 
  let valid = call_598274.validator(path, query, header, formData, body)
  let scheme = call_598274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598274.url(scheme.get, call_598274.host, call_598274.base,
                         call_598274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598274, url, valid)

proc call*(call_598275: Call_GetInfrastructureConfiguration_598263;
          infrastructureConfigurationArn: string): Recallable =
  ## getInfrastructureConfiguration
  ##  Gets a infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration that you wish to retrieve. 
  var query_598276 = newJObject()
  add(query_598276, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_598275.call(nil, query_598276, nil, nil, nil)

var getInfrastructureConfiguration* = Call_GetInfrastructureConfiguration_598263(
    name: "getInfrastructureConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_GetInfrastructureConfiguration_598264, base: "/",
    url: url_GetInfrastructureConfiguration_598265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportComponent_598277 = ref object of OpenApiRestCall_597389
proc url_ImportComponent_598279(protocol: Scheme; host: string; base: string;
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

proc validate_ImportComponent_598278(path: JsonNode; query: JsonNode;
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
  var valid_598280 = header.getOrDefault("X-Amz-Signature")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Signature", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Content-Sha256", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-Date")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Date", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Credential")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Credential", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Security-Token")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Security-Token", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Algorithm")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Algorithm", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-SignedHeaders", valid_598286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598288: Call_ImportComponent_598277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports a component and transforms its data into a component document. 
  ## 
  let valid = call_598288.validator(path, query, header, formData, body)
  let scheme = call_598288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598288.url(scheme.get, call_598288.host, call_598288.base,
                         call_598288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598288, url, valid)

proc call*(call_598289: Call_ImportComponent_598277; body: JsonNode): Recallable =
  ## importComponent
  ##  Imports a component and transforms its data into a component document. 
  ##   body: JObject (required)
  var body_598290 = newJObject()
  if body != nil:
    body_598290 = body
  result = call_598289.call(nil, nil, nil, nil, body_598290)

var importComponent* = Call_ImportComponent_598277(name: "importComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/ImportComponent", validator: validate_ImportComponent_598278,
    base: "/", url: url_ImportComponent_598279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponentBuildVersions_598291 = ref object of OpenApiRestCall_597389
proc url_ListComponentBuildVersions_598293(protocol: Scheme; host: string;
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

proc validate_ListComponentBuildVersions_598292(path: JsonNode; query: JsonNode;
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
  var valid_598294 = query.getOrDefault("nextToken")
  valid_598294 = validateParameter(valid_598294, JString, required = false,
                                 default = nil)
  if valid_598294 != nil:
    section.add "nextToken", valid_598294
  var valid_598295 = query.getOrDefault("maxResults")
  valid_598295 = validateParameter(valid_598295, JString, required = false,
                                 default = nil)
  if valid_598295 != nil:
    section.add "maxResults", valid_598295
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
  var valid_598296 = header.getOrDefault("X-Amz-Signature")
  valid_598296 = validateParameter(valid_598296, JString, required = false,
                                 default = nil)
  if valid_598296 != nil:
    section.add "X-Amz-Signature", valid_598296
  var valid_598297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598297 = validateParameter(valid_598297, JString, required = false,
                                 default = nil)
  if valid_598297 != nil:
    section.add "X-Amz-Content-Sha256", valid_598297
  var valid_598298 = header.getOrDefault("X-Amz-Date")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "X-Amz-Date", valid_598298
  var valid_598299 = header.getOrDefault("X-Amz-Credential")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "X-Amz-Credential", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Security-Token")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Security-Token", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Algorithm")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Algorithm", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-SignedHeaders", valid_598302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598304: Call_ListComponentBuildVersions_598291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_598304.validator(path, query, header, formData, body)
  let scheme = call_598304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598304.url(scheme.get, call_598304.host, call_598304.base,
                         call_598304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598304, url, valid)

proc call*(call_598305: Call_ListComponentBuildVersions_598291; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponentBuildVersions
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598306 = newJObject()
  var body_598307 = newJObject()
  add(query_598306, "nextToken", newJString(nextToken))
  if body != nil:
    body_598307 = body
  add(query_598306, "maxResults", newJString(maxResults))
  result = call_598305.call(nil, query_598306, nil, nil, body_598307)

var listComponentBuildVersions* = Call_ListComponentBuildVersions_598291(
    name: "listComponentBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListComponentBuildVersions",
    validator: validate_ListComponentBuildVersions_598292, base: "/",
    url: url_ListComponentBuildVersions_598293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_598308 = ref object of OpenApiRestCall_597389
proc url_ListComponents_598310(protocol: Scheme; host: string; base: string;
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

proc validate_ListComponents_598309(path: JsonNode; query: JsonNode;
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
  var valid_598311 = query.getOrDefault("nextToken")
  valid_598311 = validateParameter(valid_598311, JString, required = false,
                                 default = nil)
  if valid_598311 != nil:
    section.add "nextToken", valid_598311
  var valid_598312 = query.getOrDefault("maxResults")
  valid_598312 = validateParameter(valid_598312, JString, required = false,
                                 default = nil)
  if valid_598312 != nil:
    section.add "maxResults", valid_598312
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
  var valid_598313 = header.getOrDefault("X-Amz-Signature")
  valid_598313 = validateParameter(valid_598313, JString, required = false,
                                 default = nil)
  if valid_598313 != nil:
    section.add "X-Amz-Signature", valid_598313
  var valid_598314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598314 = validateParameter(valid_598314, JString, required = false,
                                 default = nil)
  if valid_598314 != nil:
    section.add "X-Amz-Content-Sha256", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Date")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Date", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Credential")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Credential", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Security-Token")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Security-Token", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Algorithm")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Algorithm", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-SignedHeaders", valid_598319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598321: Call_ListComponents_598308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_598321.validator(path, query, header, formData, body)
  let scheme = call_598321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598321.url(scheme.get, call_598321.host, call_598321.base,
                         call_598321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598321, url, valid)

proc call*(call_598322: Call_ListComponents_598308; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listComponents
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598323 = newJObject()
  var body_598324 = newJObject()
  add(query_598323, "nextToken", newJString(nextToken))
  if body != nil:
    body_598324 = body
  add(query_598323, "maxResults", newJString(maxResults))
  result = call_598322.call(nil, query_598323, nil, nil, body_598324)

var listComponents* = Call_ListComponents_598308(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListComponents", validator: validate_ListComponents_598309, base: "/",
    url: url_ListComponents_598310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionConfigurations_598325 = ref object of OpenApiRestCall_597389
proc url_ListDistributionConfigurations_598327(protocol: Scheme; host: string;
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

proc validate_ListDistributionConfigurations_598326(path: JsonNode;
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
  var valid_598328 = query.getOrDefault("nextToken")
  valid_598328 = validateParameter(valid_598328, JString, required = false,
                                 default = nil)
  if valid_598328 != nil:
    section.add "nextToken", valid_598328
  var valid_598329 = query.getOrDefault("maxResults")
  valid_598329 = validateParameter(valid_598329, JString, required = false,
                                 default = nil)
  if valid_598329 != nil:
    section.add "maxResults", valid_598329
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
  var valid_598330 = header.getOrDefault("X-Amz-Signature")
  valid_598330 = validateParameter(valid_598330, JString, required = false,
                                 default = nil)
  if valid_598330 != nil:
    section.add "X-Amz-Signature", valid_598330
  var valid_598331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "X-Amz-Content-Sha256", valid_598331
  var valid_598332 = header.getOrDefault("X-Amz-Date")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Date", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Credential")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Credential", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Security-Token")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Security-Token", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Algorithm")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Algorithm", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-SignedHeaders", valid_598336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598338: Call_ListDistributionConfigurations_598325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_598338.validator(path, query, header, formData, body)
  let scheme = call_598338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598338.url(scheme.get, call_598338.host, call_598338.base,
                         call_598338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598338, url, valid)

proc call*(call_598339: Call_ListDistributionConfigurations_598325; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDistributionConfigurations
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598340 = newJObject()
  var body_598341 = newJObject()
  add(query_598340, "nextToken", newJString(nextToken))
  if body != nil:
    body_598341 = body
  add(query_598340, "maxResults", newJString(maxResults))
  result = call_598339.call(nil, query_598340, nil, nil, body_598341)

var listDistributionConfigurations* = Call_ListDistributionConfigurations_598325(
    name: "listDistributionConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListDistributionConfigurations",
    validator: validate_ListDistributionConfigurations_598326, base: "/",
    url: url_ListDistributionConfigurations_598327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageBuildVersions_598342 = ref object of OpenApiRestCall_597389
proc url_ListImageBuildVersions_598344(protocol: Scheme; host: string; base: string;
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

proc validate_ListImageBuildVersions_598343(path: JsonNode; query: JsonNode;
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
  var valid_598345 = query.getOrDefault("nextToken")
  valid_598345 = validateParameter(valid_598345, JString, required = false,
                                 default = nil)
  if valid_598345 != nil:
    section.add "nextToken", valid_598345
  var valid_598346 = query.getOrDefault("maxResults")
  valid_598346 = validateParameter(valid_598346, JString, required = false,
                                 default = nil)
  if valid_598346 != nil:
    section.add "maxResults", valid_598346
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
  var valid_598347 = header.getOrDefault("X-Amz-Signature")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Signature", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Content-Sha256", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Date")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Date", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Credential")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Credential", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Security-Token")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Security-Token", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Algorithm")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Algorithm", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-SignedHeaders", valid_598353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598355: Call_ListImageBuildVersions_598342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_598355.validator(path, query, header, formData, body)
  let scheme = call_598355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598355.url(scheme.get, call_598355.host, call_598355.base,
                         call_598355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598355, url, valid)

proc call*(call_598356: Call_ListImageBuildVersions_598342; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageBuildVersions
  ##  Returns a list of distribution configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598357 = newJObject()
  var body_598358 = newJObject()
  add(query_598357, "nextToken", newJString(nextToken))
  if body != nil:
    body_598358 = body
  add(query_598357, "maxResults", newJString(maxResults))
  result = call_598356.call(nil, query_598357, nil, nil, body_598358)

var listImageBuildVersions* = Call_ListImageBuildVersions_598342(
    name: "listImageBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageBuildVersions",
    validator: validate_ListImageBuildVersions_598343, base: "/",
    url: url_ListImageBuildVersions_598344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelineImages_598359 = ref object of OpenApiRestCall_597389
proc url_ListImagePipelineImages_598361(protocol: Scheme; host: string; base: string;
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

proc validate_ListImagePipelineImages_598360(path: JsonNode; query: JsonNode;
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
  var valid_598362 = query.getOrDefault("nextToken")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "nextToken", valid_598362
  var valid_598363 = query.getOrDefault("maxResults")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "maxResults", valid_598363
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
  var valid_598364 = header.getOrDefault("X-Amz-Signature")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Signature", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Content-Sha256", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Date")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Date", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Credential")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Credential", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-Security-Token")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-Security-Token", valid_598368
  var valid_598369 = header.getOrDefault("X-Amz-Algorithm")
  valid_598369 = validateParameter(valid_598369, JString, required = false,
                                 default = nil)
  if valid_598369 != nil:
    section.add "X-Amz-Algorithm", valid_598369
  var valid_598370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598370 = validateParameter(valid_598370, JString, required = false,
                                 default = nil)
  if valid_598370 != nil:
    section.add "X-Amz-SignedHeaders", valid_598370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598372: Call_ListImagePipelineImages_598359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  let valid = call_598372.validator(path, query, header, formData, body)
  let scheme = call_598372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598372.url(scheme.get, call_598372.host, call_598372.base,
                         call_598372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598372, url, valid)

proc call*(call_598373: Call_ListImagePipelineImages_598359; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelineImages
  ##  Returns a list of images created by the specified pipeline. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598374 = newJObject()
  var body_598375 = newJObject()
  add(query_598374, "nextToken", newJString(nextToken))
  if body != nil:
    body_598375 = body
  add(query_598374, "maxResults", newJString(maxResults))
  result = call_598373.call(nil, query_598374, nil, nil, body_598375)

var listImagePipelineImages* = Call_ListImagePipelineImages_598359(
    name: "listImagePipelineImages", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelineImages",
    validator: validate_ListImagePipelineImages_598360, base: "/",
    url: url_ListImagePipelineImages_598361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelines_598376 = ref object of OpenApiRestCall_597389
proc url_ListImagePipelines_598378(protocol: Scheme; host: string; base: string;
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

proc validate_ListImagePipelines_598377(path: JsonNode; query: JsonNode;
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
  var valid_598379 = query.getOrDefault("nextToken")
  valid_598379 = validateParameter(valid_598379, JString, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "nextToken", valid_598379
  var valid_598380 = query.getOrDefault("maxResults")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "maxResults", valid_598380
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
  var valid_598381 = header.getOrDefault("X-Amz-Signature")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "X-Amz-Signature", valid_598381
  var valid_598382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Content-Sha256", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Date")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Date", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Credential")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Credential", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-Security-Token")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-Security-Token", valid_598385
  var valid_598386 = header.getOrDefault("X-Amz-Algorithm")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Algorithm", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-SignedHeaders", valid_598387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598389: Call_ListImagePipelines_598376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of image pipelines. 
  ## 
  let valid = call_598389.validator(path, query, header, formData, body)
  let scheme = call_598389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598389.url(scheme.get, call_598389.host, call_598389.base,
                         call_598389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598389, url, valid)

proc call*(call_598390: Call_ListImagePipelines_598376; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImagePipelines
  ## Returns a list of image pipelines. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598391 = newJObject()
  var body_598392 = newJObject()
  add(query_598391, "nextToken", newJString(nextToken))
  if body != nil:
    body_598392 = body
  add(query_598391, "maxResults", newJString(maxResults))
  result = call_598390.call(nil, query_598391, nil, nil, body_598392)

var listImagePipelines* = Call_ListImagePipelines_598376(
    name: "listImagePipelines", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelines",
    validator: validate_ListImagePipelines_598377, base: "/",
    url: url_ListImagePipelines_598378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageRecipes_598393 = ref object of OpenApiRestCall_597389
proc url_ListImageRecipes_598395(protocol: Scheme; host: string; base: string;
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

proc validate_ListImageRecipes_598394(path: JsonNode; query: JsonNode;
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
  var valid_598396 = query.getOrDefault("nextToken")
  valid_598396 = validateParameter(valid_598396, JString, required = false,
                                 default = nil)
  if valid_598396 != nil:
    section.add "nextToken", valid_598396
  var valid_598397 = query.getOrDefault("maxResults")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "maxResults", valid_598397
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
  var valid_598398 = header.getOrDefault("X-Amz-Signature")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Signature", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Content-Sha256", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Date")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Date", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Credential")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Credential", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-Security-Token")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Security-Token", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-Algorithm")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-Algorithm", valid_598403
  var valid_598404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598404 = validateParameter(valid_598404, JString, required = false,
                                 default = nil)
  if valid_598404 != nil:
    section.add "X-Amz-SignedHeaders", valid_598404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598406: Call_ListImageRecipes_598393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of image recipes. 
  ## 
  let valid = call_598406.validator(path, query, header, formData, body)
  let scheme = call_598406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598406.url(scheme.get, call_598406.host, call_598406.base,
                         call_598406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598406, url, valid)

proc call*(call_598407: Call_ListImageRecipes_598393; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImageRecipes
  ##  Returns a list of image recipes. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598408 = newJObject()
  var body_598409 = newJObject()
  add(query_598408, "nextToken", newJString(nextToken))
  if body != nil:
    body_598409 = body
  add(query_598408, "maxResults", newJString(maxResults))
  result = call_598407.call(nil, query_598408, nil, nil, body_598409)

var listImageRecipes* = Call_ListImageRecipes_598393(name: "listImageRecipes",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListImageRecipes", validator: validate_ListImageRecipes_598394,
    base: "/", url: url_ListImageRecipes_598395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_598410 = ref object of OpenApiRestCall_597389
proc url_ListImages_598412(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListImages_598411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598413 = query.getOrDefault("nextToken")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "nextToken", valid_598413
  var valid_598414 = query.getOrDefault("maxResults")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "maxResults", valid_598414
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
  var valid_598415 = header.getOrDefault("X-Amz-Signature")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Signature", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Content-Sha256", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-Date")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-Date", valid_598417
  var valid_598418 = header.getOrDefault("X-Amz-Credential")
  valid_598418 = validateParameter(valid_598418, JString, required = false,
                                 default = nil)
  if valid_598418 != nil:
    section.add "X-Amz-Credential", valid_598418
  var valid_598419 = header.getOrDefault("X-Amz-Security-Token")
  valid_598419 = validateParameter(valid_598419, JString, required = false,
                                 default = nil)
  if valid_598419 != nil:
    section.add "X-Amz-Security-Token", valid_598419
  var valid_598420 = header.getOrDefault("X-Amz-Algorithm")
  valid_598420 = validateParameter(valid_598420, JString, required = false,
                                 default = nil)
  if valid_598420 != nil:
    section.add "X-Amz-Algorithm", valid_598420
  var valid_598421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598421 = validateParameter(valid_598421, JString, required = false,
                                 default = nil)
  if valid_598421 != nil:
    section.add "X-Amz-SignedHeaders", valid_598421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598423: Call_ListImages_598410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  let valid = call_598423.validator(path, query, header, formData, body)
  let scheme = call_598423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598423.url(scheme.get, call_598423.host, call_598423.base,
                         call_598423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598423, url, valid)

proc call*(call_598424: Call_ListImages_598410; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ##  Returns the list of image build versions for the specified semantic version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598425 = newJObject()
  var body_598426 = newJObject()
  add(query_598425, "nextToken", newJString(nextToken))
  if body != nil:
    body_598426 = body
  add(query_598425, "maxResults", newJString(maxResults))
  result = call_598424.call(nil, query_598425, nil, nil, body_598426)

var listImages* = Call_ListImages_598410(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "imagebuilder.amazonaws.com",
                                      route: "/ListImages",
                                      validator: validate_ListImages_598411,
                                      base: "/", url: url_ListImages_598412,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInfrastructureConfigurations_598427 = ref object of OpenApiRestCall_597389
proc url_ListInfrastructureConfigurations_598429(protocol: Scheme; host: string;
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

proc validate_ListInfrastructureConfigurations_598428(path: JsonNode;
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
  var valid_598430 = query.getOrDefault("nextToken")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "nextToken", valid_598430
  var valid_598431 = query.getOrDefault("maxResults")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "maxResults", valid_598431
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
  var valid_598432 = header.getOrDefault("X-Amz-Signature")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Signature", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-Content-Sha256", valid_598433
  var valid_598434 = header.getOrDefault("X-Amz-Date")
  valid_598434 = validateParameter(valid_598434, JString, required = false,
                                 default = nil)
  if valid_598434 != nil:
    section.add "X-Amz-Date", valid_598434
  var valid_598435 = header.getOrDefault("X-Amz-Credential")
  valid_598435 = validateParameter(valid_598435, JString, required = false,
                                 default = nil)
  if valid_598435 != nil:
    section.add "X-Amz-Credential", valid_598435
  var valid_598436 = header.getOrDefault("X-Amz-Security-Token")
  valid_598436 = validateParameter(valid_598436, JString, required = false,
                                 default = nil)
  if valid_598436 != nil:
    section.add "X-Amz-Security-Token", valid_598436
  var valid_598437 = header.getOrDefault("X-Amz-Algorithm")
  valid_598437 = validateParameter(valid_598437, JString, required = false,
                                 default = nil)
  if valid_598437 != nil:
    section.add "X-Amz-Algorithm", valid_598437
  var valid_598438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598438 = validateParameter(valid_598438, JString, required = false,
                                 default = nil)
  if valid_598438 != nil:
    section.add "X-Amz-SignedHeaders", valid_598438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598440: Call_ListInfrastructureConfigurations_598427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of infrastructure configurations. 
  ## 
  let valid = call_598440.validator(path, query, header, formData, body)
  let scheme = call_598440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598440.url(scheme.get, call_598440.host, call_598440.base,
                         call_598440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598440, url, valid)

proc call*(call_598441: Call_ListInfrastructureConfigurations_598427;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listInfrastructureConfigurations
  ##  Returns a list of infrastructure configurations. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598442 = newJObject()
  var body_598443 = newJObject()
  add(query_598442, "nextToken", newJString(nextToken))
  if body != nil:
    body_598443 = body
  add(query_598442, "maxResults", newJString(maxResults))
  result = call_598441.call(nil, query_598442, nil, nil, body_598443)

var listInfrastructureConfigurations* = Call_ListInfrastructureConfigurations_598427(
    name: "listInfrastructureConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListInfrastructureConfigurations",
    validator: validate_ListInfrastructureConfigurations_598428, base: "/",
    url: url_ListInfrastructureConfigurations_598429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598472 = ref object of OpenApiRestCall_597389
proc url_TagResource_598474(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598475 = path.getOrDefault("resourceArn")
  valid_598475 = validateParameter(valid_598475, JString, required = true,
                                 default = nil)
  if valid_598475 != nil:
    section.add "resourceArn", valid_598475
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
  var valid_598476 = header.getOrDefault("X-Amz-Signature")
  valid_598476 = validateParameter(valid_598476, JString, required = false,
                                 default = nil)
  if valid_598476 != nil:
    section.add "X-Amz-Signature", valid_598476
  var valid_598477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598477 = validateParameter(valid_598477, JString, required = false,
                                 default = nil)
  if valid_598477 != nil:
    section.add "X-Amz-Content-Sha256", valid_598477
  var valid_598478 = header.getOrDefault("X-Amz-Date")
  valid_598478 = validateParameter(valid_598478, JString, required = false,
                                 default = nil)
  if valid_598478 != nil:
    section.add "X-Amz-Date", valid_598478
  var valid_598479 = header.getOrDefault("X-Amz-Credential")
  valid_598479 = validateParameter(valid_598479, JString, required = false,
                                 default = nil)
  if valid_598479 != nil:
    section.add "X-Amz-Credential", valid_598479
  var valid_598480 = header.getOrDefault("X-Amz-Security-Token")
  valid_598480 = validateParameter(valid_598480, JString, required = false,
                                 default = nil)
  if valid_598480 != nil:
    section.add "X-Amz-Security-Token", valid_598480
  var valid_598481 = header.getOrDefault("X-Amz-Algorithm")
  valid_598481 = validateParameter(valid_598481, JString, required = false,
                                 default = nil)
  if valid_598481 != nil:
    section.add "X-Amz-Algorithm", valid_598481
  var valid_598482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598482 = validateParameter(valid_598482, JString, required = false,
                                 default = nil)
  if valid_598482 != nil:
    section.add "X-Amz-SignedHeaders", valid_598482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598484: Call_TagResource_598472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Adds a tag to a resource. 
  ## 
  let valid = call_598484.validator(path, query, header, formData, body)
  let scheme = call_598484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598484.url(scheme.get, call_598484.host, call_598484.base,
                         call_598484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598484, url, valid)

proc call*(call_598485: Call_TagResource_598472; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Adds a tag to a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to tag. 
  ##   body: JObject (required)
  var path_598486 = newJObject()
  var body_598487 = newJObject()
  add(path_598486, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_598487 = body
  result = call_598485.call(path_598486, nil, nil, nil, body_598487)

var tagResource* = Call_TagResource_598472(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_598473,
                                        base: "/", url: url_TagResource_598474,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598444 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598446(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598445(path: JsonNode; query: JsonNode;
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
  var valid_598461 = path.getOrDefault("resourceArn")
  valid_598461 = validateParameter(valid_598461, JString, required = true,
                                 default = nil)
  if valid_598461 != nil:
    section.add "resourceArn", valid_598461
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
  var valid_598462 = header.getOrDefault("X-Amz-Signature")
  valid_598462 = validateParameter(valid_598462, JString, required = false,
                                 default = nil)
  if valid_598462 != nil:
    section.add "X-Amz-Signature", valid_598462
  var valid_598463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598463 = validateParameter(valid_598463, JString, required = false,
                                 default = nil)
  if valid_598463 != nil:
    section.add "X-Amz-Content-Sha256", valid_598463
  var valid_598464 = header.getOrDefault("X-Amz-Date")
  valid_598464 = validateParameter(valid_598464, JString, required = false,
                                 default = nil)
  if valid_598464 != nil:
    section.add "X-Amz-Date", valid_598464
  var valid_598465 = header.getOrDefault("X-Amz-Credential")
  valid_598465 = validateParameter(valid_598465, JString, required = false,
                                 default = nil)
  if valid_598465 != nil:
    section.add "X-Amz-Credential", valid_598465
  var valid_598466 = header.getOrDefault("X-Amz-Security-Token")
  valid_598466 = validateParameter(valid_598466, JString, required = false,
                                 default = nil)
  if valid_598466 != nil:
    section.add "X-Amz-Security-Token", valid_598466
  var valid_598467 = header.getOrDefault("X-Amz-Algorithm")
  valid_598467 = validateParameter(valid_598467, JString, required = false,
                                 default = nil)
  if valid_598467 != nil:
    section.add "X-Amz-Algorithm", valid_598467
  var valid_598468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598468 = validateParameter(valid_598468, JString, required = false,
                                 default = nil)
  if valid_598468 != nil:
    section.add "X-Amz-SignedHeaders", valid_598468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598469: Call_ListTagsForResource_598444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns the list of tags for the specified resource. 
  ## 
  let valid = call_598469.validator(path, query, header, formData, body)
  let scheme = call_598469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598469.url(scheme.get, call_598469.host, call_598469.base,
                         call_598469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598469, url, valid)

proc call*(call_598470: Call_ListTagsForResource_598444; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  Returns the list of tags for the specified resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you wish to retrieve. 
  var path_598471 = newJObject()
  add(path_598471, "resourceArn", newJString(resourceArn))
  result = call_598470.call(path_598471, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598444(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_598445, base: "/",
    url: url_ListTagsForResource_598446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComponentPolicy_598488 = ref object of OpenApiRestCall_597389
proc url_PutComponentPolicy_598490(protocol: Scheme; host: string; base: string;
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

proc validate_PutComponentPolicy_598489(path: JsonNode; query: JsonNode;
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
  var valid_598491 = header.getOrDefault("X-Amz-Signature")
  valid_598491 = validateParameter(valid_598491, JString, required = false,
                                 default = nil)
  if valid_598491 != nil:
    section.add "X-Amz-Signature", valid_598491
  var valid_598492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598492 = validateParameter(valid_598492, JString, required = false,
                                 default = nil)
  if valid_598492 != nil:
    section.add "X-Amz-Content-Sha256", valid_598492
  var valid_598493 = header.getOrDefault("X-Amz-Date")
  valid_598493 = validateParameter(valid_598493, JString, required = false,
                                 default = nil)
  if valid_598493 != nil:
    section.add "X-Amz-Date", valid_598493
  var valid_598494 = header.getOrDefault("X-Amz-Credential")
  valid_598494 = validateParameter(valid_598494, JString, required = false,
                                 default = nil)
  if valid_598494 != nil:
    section.add "X-Amz-Credential", valid_598494
  var valid_598495 = header.getOrDefault("X-Amz-Security-Token")
  valid_598495 = validateParameter(valid_598495, JString, required = false,
                                 default = nil)
  if valid_598495 != nil:
    section.add "X-Amz-Security-Token", valid_598495
  var valid_598496 = header.getOrDefault("X-Amz-Algorithm")
  valid_598496 = validateParameter(valid_598496, JString, required = false,
                                 default = nil)
  if valid_598496 != nil:
    section.add "X-Amz-Algorithm", valid_598496
  var valid_598497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598497 = validateParameter(valid_598497, JString, required = false,
                                 default = nil)
  if valid_598497 != nil:
    section.add "X-Amz-SignedHeaders", valid_598497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598499: Call_PutComponentPolicy_598488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to a component. 
  ## 
  let valid = call_598499.validator(path, query, header, formData, body)
  let scheme = call_598499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598499.url(scheme.get, call_598499.host, call_598499.base,
                         call_598499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598499, url, valid)

proc call*(call_598500: Call_PutComponentPolicy_598488; body: JsonNode): Recallable =
  ## putComponentPolicy
  ##  Applies a policy to a component. 
  ##   body: JObject (required)
  var body_598501 = newJObject()
  if body != nil:
    body_598501 = body
  result = call_598500.call(nil, nil, nil, nil, body_598501)

var putComponentPolicy* = Call_PutComponentPolicy_598488(
    name: "putComponentPolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutComponentPolicy",
    validator: validate_PutComponentPolicy_598489, base: "/",
    url: url_PutComponentPolicy_598490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImagePolicy_598502 = ref object of OpenApiRestCall_597389
proc url_PutImagePolicy_598504(protocol: Scheme; host: string; base: string;
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

proc validate_PutImagePolicy_598503(path: JsonNode; query: JsonNode;
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
  var valid_598505 = header.getOrDefault("X-Amz-Signature")
  valid_598505 = validateParameter(valid_598505, JString, required = false,
                                 default = nil)
  if valid_598505 != nil:
    section.add "X-Amz-Signature", valid_598505
  var valid_598506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598506 = validateParameter(valid_598506, JString, required = false,
                                 default = nil)
  if valid_598506 != nil:
    section.add "X-Amz-Content-Sha256", valid_598506
  var valid_598507 = header.getOrDefault("X-Amz-Date")
  valid_598507 = validateParameter(valid_598507, JString, required = false,
                                 default = nil)
  if valid_598507 != nil:
    section.add "X-Amz-Date", valid_598507
  var valid_598508 = header.getOrDefault("X-Amz-Credential")
  valid_598508 = validateParameter(valid_598508, JString, required = false,
                                 default = nil)
  if valid_598508 != nil:
    section.add "X-Amz-Credential", valid_598508
  var valid_598509 = header.getOrDefault("X-Amz-Security-Token")
  valid_598509 = validateParameter(valid_598509, JString, required = false,
                                 default = nil)
  if valid_598509 != nil:
    section.add "X-Amz-Security-Token", valid_598509
  var valid_598510 = header.getOrDefault("X-Amz-Algorithm")
  valid_598510 = validateParameter(valid_598510, JString, required = false,
                                 default = nil)
  if valid_598510 != nil:
    section.add "X-Amz-Algorithm", valid_598510
  var valid_598511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598511 = validateParameter(valid_598511, JString, required = false,
                                 default = nil)
  if valid_598511 != nil:
    section.add "X-Amz-SignedHeaders", valid_598511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598513: Call_PutImagePolicy_598502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image. 
  ## 
  let valid = call_598513.validator(path, query, header, formData, body)
  let scheme = call_598513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598513.url(scheme.get, call_598513.host, call_598513.base,
                         call_598513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598513, url, valid)

proc call*(call_598514: Call_PutImagePolicy_598502; body: JsonNode): Recallable =
  ## putImagePolicy
  ##  Applies a policy to an image. 
  ##   body: JObject (required)
  var body_598515 = newJObject()
  if body != nil:
    body_598515 = body
  result = call_598514.call(nil, nil, nil, nil, body_598515)

var putImagePolicy* = Call_PutImagePolicy_598502(name: "putImagePolicy",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/PutImagePolicy", validator: validate_PutImagePolicy_598503, base: "/",
    url: url_PutImagePolicy_598504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageRecipePolicy_598516 = ref object of OpenApiRestCall_597389
proc url_PutImageRecipePolicy_598518(protocol: Scheme; host: string; base: string;
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

proc validate_PutImageRecipePolicy_598517(path: JsonNode; query: JsonNode;
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
  var valid_598519 = header.getOrDefault("X-Amz-Signature")
  valid_598519 = validateParameter(valid_598519, JString, required = false,
                                 default = nil)
  if valid_598519 != nil:
    section.add "X-Amz-Signature", valid_598519
  var valid_598520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598520 = validateParameter(valid_598520, JString, required = false,
                                 default = nil)
  if valid_598520 != nil:
    section.add "X-Amz-Content-Sha256", valid_598520
  var valid_598521 = header.getOrDefault("X-Amz-Date")
  valid_598521 = validateParameter(valid_598521, JString, required = false,
                                 default = nil)
  if valid_598521 != nil:
    section.add "X-Amz-Date", valid_598521
  var valid_598522 = header.getOrDefault("X-Amz-Credential")
  valid_598522 = validateParameter(valid_598522, JString, required = false,
                                 default = nil)
  if valid_598522 != nil:
    section.add "X-Amz-Credential", valid_598522
  var valid_598523 = header.getOrDefault("X-Amz-Security-Token")
  valid_598523 = validateParameter(valid_598523, JString, required = false,
                                 default = nil)
  if valid_598523 != nil:
    section.add "X-Amz-Security-Token", valid_598523
  var valid_598524 = header.getOrDefault("X-Amz-Algorithm")
  valid_598524 = validateParameter(valid_598524, JString, required = false,
                                 default = nil)
  if valid_598524 != nil:
    section.add "X-Amz-Algorithm", valid_598524
  var valid_598525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598525 = validateParameter(valid_598525, JString, required = false,
                                 default = nil)
  if valid_598525 != nil:
    section.add "X-Amz-SignedHeaders", valid_598525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598527: Call_PutImageRecipePolicy_598516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Applies a policy to an image recipe. 
  ## 
  let valid = call_598527.validator(path, query, header, formData, body)
  let scheme = call_598527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598527.url(scheme.get, call_598527.host, call_598527.base,
                         call_598527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598527, url, valid)

proc call*(call_598528: Call_PutImageRecipePolicy_598516; body: JsonNode): Recallable =
  ## putImageRecipePolicy
  ##  Applies a policy to an image recipe. 
  ##   body: JObject (required)
  var body_598529 = newJObject()
  if body != nil:
    body_598529 = body
  result = call_598528.call(nil, nil, nil, nil, body_598529)

var putImageRecipePolicy* = Call_PutImageRecipePolicy_598516(
    name: "putImageRecipePolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutImageRecipePolicy",
    validator: validate_PutImageRecipePolicy_598517, base: "/",
    url: url_PutImageRecipePolicy_598518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImagePipelineExecution_598530 = ref object of OpenApiRestCall_597389
proc url_StartImagePipelineExecution_598532(protocol: Scheme; host: string;
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

proc validate_StartImagePipelineExecution_598531(path: JsonNode; query: JsonNode;
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
  var valid_598533 = header.getOrDefault("X-Amz-Signature")
  valid_598533 = validateParameter(valid_598533, JString, required = false,
                                 default = nil)
  if valid_598533 != nil:
    section.add "X-Amz-Signature", valid_598533
  var valid_598534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598534 = validateParameter(valid_598534, JString, required = false,
                                 default = nil)
  if valid_598534 != nil:
    section.add "X-Amz-Content-Sha256", valid_598534
  var valid_598535 = header.getOrDefault("X-Amz-Date")
  valid_598535 = validateParameter(valid_598535, JString, required = false,
                                 default = nil)
  if valid_598535 != nil:
    section.add "X-Amz-Date", valid_598535
  var valid_598536 = header.getOrDefault("X-Amz-Credential")
  valid_598536 = validateParameter(valid_598536, JString, required = false,
                                 default = nil)
  if valid_598536 != nil:
    section.add "X-Amz-Credential", valid_598536
  var valid_598537 = header.getOrDefault("X-Amz-Security-Token")
  valid_598537 = validateParameter(valid_598537, JString, required = false,
                                 default = nil)
  if valid_598537 != nil:
    section.add "X-Amz-Security-Token", valid_598537
  var valid_598538 = header.getOrDefault("X-Amz-Algorithm")
  valid_598538 = validateParameter(valid_598538, JString, required = false,
                                 default = nil)
  if valid_598538 != nil:
    section.add "X-Amz-Algorithm", valid_598538
  var valid_598539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598539 = validateParameter(valid_598539, JString, required = false,
                                 default = nil)
  if valid_598539 != nil:
    section.add "X-Amz-SignedHeaders", valid_598539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598541: Call_StartImagePipelineExecution_598530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  let valid = call_598541.validator(path, query, header, formData, body)
  let scheme = call_598541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598541.url(scheme.get, call_598541.host, call_598541.base,
                         call_598541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598541, url, valid)

proc call*(call_598542: Call_StartImagePipelineExecution_598530; body: JsonNode): Recallable =
  ## startImagePipelineExecution
  ##  Manually triggers a pipeline to create an image. 
  ##   body: JObject (required)
  var body_598543 = newJObject()
  if body != nil:
    body_598543 = body
  result = call_598542.call(nil, nil, nil, nil, body_598543)

var startImagePipelineExecution* = Call_StartImagePipelineExecution_598530(
    name: "startImagePipelineExecution", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/StartImagePipelineExecution",
    validator: validate_StartImagePipelineExecution_598531, base: "/",
    url: url_StartImagePipelineExecution_598532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598544 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598546(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598547 = path.getOrDefault("resourceArn")
  valid_598547 = validateParameter(valid_598547, JString, required = true,
                                 default = nil)
  if valid_598547 != nil:
    section.add "resourceArn", valid_598547
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598548 = query.getOrDefault("tagKeys")
  valid_598548 = validateParameter(valid_598548, JArray, required = true, default = nil)
  if valid_598548 != nil:
    section.add "tagKeys", valid_598548
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
  var valid_598549 = header.getOrDefault("X-Amz-Signature")
  valid_598549 = validateParameter(valid_598549, JString, required = false,
                                 default = nil)
  if valid_598549 != nil:
    section.add "X-Amz-Signature", valid_598549
  var valid_598550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598550 = validateParameter(valid_598550, JString, required = false,
                                 default = nil)
  if valid_598550 != nil:
    section.add "X-Amz-Content-Sha256", valid_598550
  var valid_598551 = header.getOrDefault("X-Amz-Date")
  valid_598551 = validateParameter(valid_598551, JString, required = false,
                                 default = nil)
  if valid_598551 != nil:
    section.add "X-Amz-Date", valid_598551
  var valid_598552 = header.getOrDefault("X-Amz-Credential")
  valid_598552 = validateParameter(valid_598552, JString, required = false,
                                 default = nil)
  if valid_598552 != nil:
    section.add "X-Amz-Credential", valid_598552
  var valid_598553 = header.getOrDefault("X-Amz-Security-Token")
  valid_598553 = validateParameter(valid_598553, JString, required = false,
                                 default = nil)
  if valid_598553 != nil:
    section.add "X-Amz-Security-Token", valid_598553
  var valid_598554 = header.getOrDefault("X-Amz-Algorithm")
  valid_598554 = validateParameter(valid_598554, JString, required = false,
                                 default = nil)
  if valid_598554 != nil:
    section.add "X-Amz-Algorithm", valid_598554
  var valid_598555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598555 = validateParameter(valid_598555, JString, required = false,
                                 default = nil)
  if valid_598555 != nil:
    section.add "X-Amz-SignedHeaders", valid_598555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598556: Call_UntagResource_598544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Removes a tag from a resource. 
  ## 
  let valid = call_598556.validator(path, query, header, formData, body)
  let scheme = call_598556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598556.url(scheme.get, call_598556.host, call_598556.base,
                         call_598556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598556, url, valid)

proc call*(call_598557: Call_UntagResource_598544; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Removes a tag from a resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you wish to untag. 
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  var path_598558 = newJObject()
  var query_598559 = newJObject()
  add(path_598558, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_598559.add "tagKeys", tagKeys
  result = call_598557.call(path_598558, query_598559, nil, nil, nil)

var untagResource* = Call_UntagResource_598544(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_598545,
    base: "/", url: url_UntagResource_598546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistributionConfiguration_598560 = ref object of OpenApiRestCall_597389
proc url_UpdateDistributionConfiguration_598562(protocol: Scheme; host: string;
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

proc validate_UpdateDistributionConfiguration_598561(path: JsonNode;
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
  var valid_598563 = header.getOrDefault("X-Amz-Signature")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Signature", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Content-Sha256", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-Date")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Date", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-Credential")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-Credential", valid_598566
  var valid_598567 = header.getOrDefault("X-Amz-Security-Token")
  valid_598567 = validateParameter(valid_598567, JString, required = false,
                                 default = nil)
  if valid_598567 != nil:
    section.add "X-Amz-Security-Token", valid_598567
  var valid_598568 = header.getOrDefault("X-Amz-Algorithm")
  valid_598568 = validateParameter(valid_598568, JString, required = false,
                                 default = nil)
  if valid_598568 != nil:
    section.add "X-Amz-Algorithm", valid_598568
  var valid_598569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598569 = validateParameter(valid_598569, JString, required = false,
                                 default = nil)
  if valid_598569 != nil:
    section.add "X-Amz-SignedHeaders", valid_598569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598571: Call_UpdateDistributionConfiguration_598560;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_598571.validator(path, query, header, formData, body)
  let scheme = call_598571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598571.url(scheme.get, call_598571.host, call_598571.base,
                         call_598571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598571, url, valid)

proc call*(call_598572: Call_UpdateDistributionConfiguration_598560; body: JsonNode): Recallable =
  ## updateDistributionConfiguration
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_598573 = newJObject()
  if body != nil:
    body_598573 = body
  result = call_598572.call(nil, nil, nil, nil, body_598573)

var updateDistributionConfiguration* = Call_UpdateDistributionConfiguration_598560(
    name: "updateDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateDistributionConfiguration",
    validator: validate_UpdateDistributionConfiguration_598561, base: "/",
    url: url_UpdateDistributionConfiguration_598562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePipeline_598574 = ref object of OpenApiRestCall_597389
proc url_UpdateImagePipeline_598576(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateImagePipeline_598575(path: JsonNode; query: JsonNode;
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
  var valid_598577 = header.getOrDefault("X-Amz-Signature")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "X-Amz-Signature", valid_598577
  var valid_598578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Content-Sha256", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Date")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Date", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Credential")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Credential", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-Security-Token")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-Security-Token", valid_598581
  var valid_598582 = header.getOrDefault("X-Amz-Algorithm")
  valid_598582 = validateParameter(valid_598582, JString, required = false,
                                 default = nil)
  if valid_598582 != nil:
    section.add "X-Amz-Algorithm", valid_598582
  var valid_598583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598583 = validateParameter(valid_598583, JString, required = false,
                                 default = nil)
  if valid_598583 != nil:
    section.add "X-Amz-SignedHeaders", valid_598583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598585: Call_UpdateImagePipeline_598574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_598585.validator(path, query, header, formData, body)
  let scheme = call_598585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598585.url(scheme.get, call_598585.host, call_598585.base,
                         call_598585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598585, url, valid)

proc call*(call_598586: Call_UpdateImagePipeline_598574; body: JsonNode): Recallable =
  ## updateImagePipeline
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_598587 = newJObject()
  if body != nil:
    body_598587 = body
  result = call_598586.call(nil, nil, nil, nil, body_598587)

var updateImagePipeline* = Call_UpdateImagePipeline_598574(
    name: "updateImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateImagePipeline",
    validator: validate_UpdateImagePipeline_598575, base: "/",
    url: url_UpdateImagePipeline_598576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInfrastructureConfiguration_598588 = ref object of OpenApiRestCall_597389
proc url_UpdateInfrastructureConfiguration_598590(protocol: Scheme; host: string;
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

proc validate_UpdateInfrastructureConfiguration_598589(path: JsonNode;
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
  var valid_598591 = header.getOrDefault("X-Amz-Signature")
  valid_598591 = validateParameter(valid_598591, JString, required = false,
                                 default = nil)
  if valid_598591 != nil:
    section.add "X-Amz-Signature", valid_598591
  var valid_598592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598592 = validateParameter(valid_598592, JString, required = false,
                                 default = nil)
  if valid_598592 != nil:
    section.add "X-Amz-Content-Sha256", valid_598592
  var valid_598593 = header.getOrDefault("X-Amz-Date")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = nil)
  if valid_598593 != nil:
    section.add "X-Amz-Date", valid_598593
  var valid_598594 = header.getOrDefault("X-Amz-Credential")
  valid_598594 = validateParameter(valid_598594, JString, required = false,
                                 default = nil)
  if valid_598594 != nil:
    section.add "X-Amz-Credential", valid_598594
  var valid_598595 = header.getOrDefault("X-Amz-Security-Token")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Security-Token", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Algorithm")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Algorithm", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-SignedHeaders", valid_598597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598599: Call_UpdateInfrastructureConfiguration_598588;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_598599.validator(path, query, header, formData, body)
  let scheme = call_598599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598599.url(scheme.get, call_598599.host, call_598599.base,
                         call_598599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598599, url, valid)

proc call*(call_598600: Call_UpdateInfrastructureConfiguration_598588;
          body: JsonNode): Recallable =
  ## updateInfrastructureConfiguration
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_598601 = newJObject()
  if body != nil:
    body_598601 = body
  result = call_598600.call(nil, nil, nil, nil, body_598601)

var updateInfrastructureConfiguration* = Call_UpdateInfrastructureConfiguration_598588(
    name: "updateInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateInfrastructureConfiguration",
    validator: validate_UpdateInfrastructureConfiguration_598589, base: "/",
    url: url_UpdateInfrastructureConfiguration_598590,
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
