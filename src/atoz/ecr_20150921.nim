
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EC2 Container Registry
## version: 2015-09-21
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic Container Registry</fullname> <p>Amazon Elastic Container Registry (Amazon ECR) is a managed Docker registry service. Customers can use the familiar Docker CLI to push, pull, and manage images. Amazon ECR provides a secure, scalable, and reliable registry. Amazon ECR supports private Docker repositories with resource-based permissions using IAM so that specific users or Amazon EC2 instances can access repositories and images. Developers can use the Docker CLI to author and manage images.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ecr/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.ecr.us-west-2.amazonaws.com",
                           "eu-west-2": "api.ecr.eu-west-2.amazonaws.com", "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com", "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
                           "us-east-2": "api.ecr.us-east-2.amazonaws.com",
                           "us-east-1": "api.ecr.us-east-1.amazonaws.com", "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
                           "eu-north-1": "api.ecr.eu-north-1.amazonaws.com", "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.ecr.us-west-1.amazonaws.com", "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
                           "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.ecr.eu-west-1.amazonaws.com", "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.ecr.us-west-2.amazonaws.com",
      "eu-west-2": "api.ecr.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
      "us-east-2": "api.ecr.us-east-2.amazonaws.com",
      "us-east-1": "api.ecr.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
      "eu-north-1": "api.ecr.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.ecr.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
      "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
      "eu-west-1": "api.ecr.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ecr"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchCheckLayerAvailability_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchCheckLayerAvailability_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCheckLayerAvailability_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Checks the availability of one or more image layers in a repository.</p> <p>When an image is pushed to a repository, each image layer is checked to verify if it has been uploaded before. If it is, then the image layer is skipped.</p> <p>When an image is pulled from a repository, each image layer is checked once to verify it is available to be pulled.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_BatchCheckLayerAvailability_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Checks the availability of one or more image layers in a repository.</p> <p>When an image is pushed to a repository, each image layer is checked to verify if it has been uploaded before. If it is, then the image layer is skipped.</p> <p>When an image is pulled from a repository, each image layer is checked once to verify it is available to be pulled.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_BatchCheckLayerAvailability_21625779; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Checks the availability of one or more image layers in a repository.</p> <p>When an image is pushed to a repository, each image layer is checked to verify if it has been uploaded before. If it is, then the image layer is skipped.</p> <p>When an image is pulled from a repository, each image layer is checked once to verify it is available to be pulled.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_21625779(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_21625780, base: "/",
    makeUrl: url_BatchCheckLayerAvailability_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchDeleteImage_21626031(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteImage_21626030(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a list of specified images within a repository. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_BatchDeleteImage_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a list of specified images within a repository. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchDeleteImage_21626029; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a repository. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchDeleteImage* = Call_BatchDeleteImage_21626029(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_21626030, base: "/",
    makeUrl: url_BatchDeleteImage_21626031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_21626044 = ref object of OpenApiRestCall_21625435
proc url_BatchGetImage_21626046(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetImage_21626045(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets detailed information for an image. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>When an image is pulled, the BatchGetImage API is called once to retrieve the image manifest.</p>
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_BatchGetImage_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets detailed information for an image. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>When an image is pulled, the BatchGetImage API is called once to retrieve the image manifest.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_BatchGetImage_21626044; body: JsonNode): Recallable =
  ## batchGetImage
  ## <p>Gets detailed information for an image. Images are specified with either an <code>imageTag</code> or <code>imageDigest</code>.</p> <p>When an image is pulled, the BatchGetImage API is called once to retrieve the image manifest.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var batchGetImage* = Call_BatchGetImage_21626044(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_21626045, base: "/",
    makeUrl: url_BatchGetImage_21626046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_21626059 = ref object of OpenApiRestCall_21625435
proc url_CompleteLayerUpload_21626061(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CompleteLayerUpload_21626060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <p>When an image is pushed, the CompleteLayerUpload API is called once per each new image layer to verify that the upload has completed.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_CompleteLayerUpload_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <p>When an image is pushed, the CompleteLayerUpload API is called once per each new image layer to verify that the upload has completed.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CompleteLayerUpload_21626059; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <p>When an image is pushed, the CompleteLayerUpload API is called once per each new image layer to verify that the upload has completed.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var completeLayerUpload* = Call_CompleteLayerUpload_21626059(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_21626060, base: "/",
    makeUrl: url_CompleteLayerUpload_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_21626074 = ref object of OpenApiRestCall_21625435
proc url_CreateRepository_21626076(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRepository_21626075(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_CreateRepository_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_CreateRepository_21626074; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var createRepository* = Call_CreateRepository_21626074(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_21626075, base: "/",
    makeUrl: url_CreateRepository_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_21626089 = ref object of OpenApiRestCall_21625435
proc url_DeleteLifecyclePolicy_21626091(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLifecyclePolicy_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the lifecycle policy associated with the specified repository.
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_DeleteLifecyclePolicy_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the lifecycle policy associated with the specified repository.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_DeleteLifecyclePolicy_21626089; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the lifecycle policy associated with the specified repository.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_21626089(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_21626090, base: "/",
    makeUrl: url_DeleteLifecyclePolicy_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_21626104 = ref object of OpenApiRestCall_21625435
proc url_DeleteRepository_21626106(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepository_21626105(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a repository. If the repository contains images, you must either delete all images in the repository or use the <code>force</code> option to delete the repository.
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_DeleteRepository_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a repository. If the repository contains images, you must either delete all images in the repository or use the <code>force</code> option to delete the repository.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_DeleteRepository_21626104; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes a repository. If the repository contains images, you must either delete all images in the repository or use the <code>force</code> option to delete the repository.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var deleteRepository* = Call_DeleteRepository_21626104(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_21626105, base: "/",
    makeUrl: url_DeleteRepository_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_21626119 = ref object of OpenApiRestCall_21625435
proc url_DeleteRepositoryPolicy_21626121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepositoryPolicy_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the repository policy associated with the specified repository.
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_DeleteRepositoryPolicy_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the repository policy associated with the specified repository.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_DeleteRepositoryPolicy_21626119; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy associated with the specified repository.
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_21626119(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_21626120, base: "/",
    makeUrl: url_DeleteRepositoryPolicy_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageScanFindings_21626134 = ref object of OpenApiRestCall_21625435
proc url_DescribeImageScanFindings_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImageScanFindings_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the scan findings for the specified image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626137 = query.getOrDefault("maxResults")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "maxResults", valid_21626137
  var valid_21626138 = query.getOrDefault("nextToken")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "nextToken", valid_21626138
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
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_DescribeImageScanFindings_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the scan findings for the specified image.
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_DescribeImageScanFindings_21626134; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeImageScanFindings
  ## Returns the scan findings for the specified image.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626151 = newJObject()
  var body_21626152 = newJObject()
  add(query_21626151, "maxResults", newJString(maxResults))
  add(query_21626151, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626152 = body
  result = call_21626149.call(nil, query_21626151, nil, nil, body_21626152)

var describeImageScanFindings* = Call_DescribeImageScanFindings_21626134(
    name: "describeImageScanFindings", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings",
    validator: validate_DescribeImageScanFindings_21626135, base: "/",
    makeUrl: url_DescribeImageScanFindings_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_21626156 = ref object of OpenApiRestCall_21625435
proc url_DescribeImages_21626158(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImages_21626157(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns metadata about the images in a repository.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626159 = query.getOrDefault("maxResults")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "maxResults", valid_21626159
  var valid_21626160 = query.getOrDefault("nextToken")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "nextToken", valid_21626160
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
  var valid_21626161 = header.getOrDefault("X-Amz-Date")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Date", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Security-Token", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Target")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
  if valid_21626163 != nil:
    section.add "X-Amz-Target", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Algorithm", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Signature")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Signature", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Credential")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Credential", valid_21626168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626170: Call_DescribeImages_21626156; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns metadata about the images in a repository.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_21626170.validator(path, query, header, formData, body, _)
  let scheme = call_21626170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626170.makeUrl(scheme.get, call_21626170.host, call_21626170.base,
                               call_21626170.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626170, uri, valid, _)

proc call*(call_21626171: Call_DescribeImages_21626156; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626172 = newJObject()
  var body_21626173 = newJObject()
  add(query_21626172, "maxResults", newJString(maxResults))
  add(query_21626172, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626173 = body
  result = call_21626171.call(nil, query_21626172, nil, nil, body_21626173)

var describeImages* = Call_DescribeImages_21626156(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_21626157, base: "/",
    makeUrl: url_DescribeImages_21626158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_21626174 = ref object of OpenApiRestCall_21625435
proc url_DescribeRepositories_21626176(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRepositories_21626175(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes image repositories in a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626177 = query.getOrDefault("maxResults")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "maxResults", valid_21626177
  var valid_21626178 = query.getOrDefault("nextToken")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "nextToken", valid_21626178
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
  var valid_21626179 = header.getOrDefault("X-Amz-Date")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Date", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Security-Token", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Target")
  valid_21626181 = validateParameter(valid_21626181, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
  if valid_21626181 != nil:
    section.add "X-Amz-Target", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626188: Call_DescribeRepositories_21626174; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_DescribeRepositories_21626174; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626190 = newJObject()
  var body_21626191 = newJObject()
  add(query_21626190, "maxResults", newJString(maxResults))
  add(query_21626190, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626191 = body
  result = call_21626189.call(nil, query_21626190, nil, nil, body_21626191)

var describeRepositories* = Call_DescribeRepositories_21626174(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_21626175, base: "/",
    makeUrl: url_DescribeRepositories_21626176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_21626192 = ref object of OpenApiRestCall_21625435
proc url_GetAuthorizationToken_21626194(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizationToken_21626193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves an authorization token. An authorization token represents your IAM authentication credentials and can be used to access any Amazon ECR registry that your IAM principal has access to. The authorization token is valid for 12 hours.</p> <p>The <code>authorizationToken</code> returned is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>get-login-password</code> command that simplifies the login process. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth">Registry Authentication</a> in the <i>Amazon Elastic Container Registry User Guide</i>.</p>
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
  var valid_21626195 = header.getOrDefault("X-Amz-Date")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Date", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Security-Token", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Target")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
  if valid_21626197 != nil:
    section.add "X-Amz-Target", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Algorithm", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Signature")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Signature", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Credential")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Credential", valid_21626202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626204: Call_GetAuthorizationToken_21626192;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves an authorization token. An authorization token represents your IAM authentication credentials and can be used to access any Amazon ECR registry that your IAM principal has access to. The authorization token is valid for 12 hours.</p> <p>The <code>authorizationToken</code> returned is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>get-login-password</code> command that simplifies the login process. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth">Registry Authentication</a> in the <i>Amazon Elastic Container Registry User Guide</i>.</p>
  ## 
  let valid = call_21626204.validator(path, query, header, formData, body, _)
  let scheme = call_21626204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626204.makeUrl(scheme.get, call_21626204.host, call_21626204.base,
                               call_21626204.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626204, uri, valid, _)

proc call*(call_21626205: Call_GetAuthorizationToken_21626192; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves an authorization token. An authorization token represents your IAM authentication credentials and can be used to access any Amazon ECR registry that your IAM principal has access to. The authorization token is valid for 12 hours.</p> <p>The <code>authorizationToken</code> returned is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>get-login-password</code> command that simplifies the login process. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth">Registry Authentication</a> in the <i>Amazon Elastic Container Registry User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626206 = newJObject()
  if body != nil:
    body_21626206 = body
  result = call_21626205.call(nil, nil, nil, nil, body_21626206)

var getAuthorizationToken* = Call_GetAuthorizationToken_21626192(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_21626193, base: "/",
    makeUrl: url_GetAuthorizationToken_21626194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_21626207 = ref object of OpenApiRestCall_21625435
proc url_GetDownloadUrlForLayer_21626209(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadUrlForLayer_21626208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <p>When an image is pulled, the GetDownloadUrlForLayer API is called once per image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21626210 = header.getOrDefault("X-Amz-Date")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Date", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Security-Token", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Target")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
  if valid_21626212 != nil:
    section.add "X-Amz-Target", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_GetDownloadUrlForLayer_21626207;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <p>When an image is pulled, the GetDownloadUrlForLayer API is called once per image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_GetDownloadUrlForLayer_21626207; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <p>When an image is pulled, the GetDownloadUrlForLayer API is called once per image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21626221 = newJObject()
  if body != nil:
    body_21626221 = body
  result = call_21626220.call(nil, nil, nil, nil, body_21626221)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_21626207(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_21626208, base: "/",
    makeUrl: url_GetDownloadUrlForLayer_21626209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_21626222 = ref object of OpenApiRestCall_21625435
proc url_GetLifecyclePolicy_21626224(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLifecyclePolicy_21626223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the lifecycle policy for the specified repository.
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
  var valid_21626225 = header.getOrDefault("X-Amz-Date")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Date", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Security-Token", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Target")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
  if valid_21626227 != nil:
    section.add "X-Amz-Target", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626234: Call_GetLifecyclePolicy_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the lifecycle policy for the specified repository.
  ## 
  let valid = call_21626234.validator(path, query, header, formData, body, _)
  let scheme = call_21626234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626234.makeUrl(scheme.get, call_21626234.host, call_21626234.base,
                               call_21626234.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626234, uri, valid, _)

proc call*(call_21626235: Call_GetLifecyclePolicy_21626222; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the lifecycle policy for the specified repository.
  ##   body: JObject (required)
  var body_21626236 = newJObject()
  if body != nil:
    body_21626236 = body
  result = call_21626235.call(nil, nil, nil, nil, body_21626236)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_21626222(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_21626223, base: "/",
    makeUrl: url_GetLifecyclePolicy_21626224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_21626237 = ref object of OpenApiRestCall_21625435
proc url_GetLifecyclePolicyPreview_21626239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLifecyclePolicyPreview_21626238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the results of the lifecycle policy preview request for the specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626240 = query.getOrDefault("maxResults")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "maxResults", valid_21626240
  var valid_21626241 = query.getOrDefault("nextToken")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "nextToken", valid_21626241
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
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_GetLifecyclePolicyPreview_21626237;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the results of the lifecycle policy preview request for the specified repository.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_GetLifecyclePolicyPreview_21626237; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the lifecycle policy preview request for the specified repository.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626253 = newJObject()
  var body_21626254 = newJObject()
  add(query_21626253, "maxResults", newJString(maxResults))
  add(query_21626253, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626254 = body
  result = call_21626252.call(nil, query_21626253, nil, nil, body_21626254)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_21626237(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_21626238, base: "/",
    makeUrl: url_GetLifecyclePolicyPreview_21626239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_21626255 = ref object of OpenApiRestCall_21625435
proc url_GetRepositoryPolicy_21626257(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepositoryPolicy_21626256(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the repository policy for the specified repository.
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
  var valid_21626258 = header.getOrDefault("X-Amz-Date")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Date", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Security-Token", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Target")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_21626260 != nil:
    section.add "X-Amz-Target", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Algorithm", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Signature")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Signature", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Credential")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Credential", valid_21626265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626267: Call_GetRepositoryPolicy_21626255; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the repository policy for the specified repository.
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_GetRepositoryPolicy_21626255; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for the specified repository.
  ##   body: JObject (required)
  var body_21626269 = newJObject()
  if body != nil:
    body_21626269 = body
  result = call_21626268.call(nil, nil, nil, nil, body_21626269)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_21626255(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_21626256, base: "/",
    makeUrl: url_GetRepositoryPolicy_21626257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_21626270 = ref object of OpenApiRestCall_21625435
proc url_InitiateLayerUpload_21626272(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateLayerUpload_21626271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Notifies Amazon ECR that you intend to upload an image layer.</p> <p>When an image is pushed, the InitiateLayerUpload API is called once per image layer that has not already been uploaded. Whether an image layer has been uploaded before is determined by the <a>BatchCheckLayerAvailability</a> API action.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21626273 = header.getOrDefault("X-Amz-Date")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Date", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Security-Token", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Target")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_21626275 != nil:
    section.add "X-Amz-Target", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Algorithm", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Signature")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Signature", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Credential")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Credential", valid_21626280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626282: Call_InitiateLayerUpload_21626270; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Notifies Amazon ECR that you intend to upload an image layer.</p> <p>When an image is pushed, the InitiateLayerUpload API is called once per image layer that has not already been uploaded. Whether an image layer has been uploaded before is determined by the <a>BatchCheckLayerAvailability</a> API action.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21626282.validator(path, query, header, formData, body, _)
  let scheme = call_21626282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626282.makeUrl(scheme.get, call_21626282.host, call_21626282.base,
                               call_21626282.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626282, uri, valid, _)

proc call*(call_21626283: Call_InitiateLayerUpload_21626270; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notifies Amazon ECR that you intend to upload an image layer.</p> <p>When an image is pushed, the InitiateLayerUpload API is called once per image layer that has not already been uploaded. Whether an image layer has been uploaded before is determined by the <a>BatchCheckLayerAvailability</a> API action.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21626284 = newJObject()
  if body != nil:
    body_21626284 = body
  result = call_21626283.call(nil, nil, nil, nil, body_21626284)

var initiateLayerUpload* = Call_InitiateLayerUpload_21626270(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_21626271, base: "/",
    makeUrl: url_InitiateLayerUpload_21626272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_21626285 = ref object of OpenApiRestCall_21625435
proc url_ListImages_21626287(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImages_21626286(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists all the image IDs for the specified repository.</p> <p>You can filter images based on whether or not they are tagged by using the <code>tagStatus</code> filter and specifying either <code>TAGGED</code>, <code>UNTAGGED</code> or <code>ANY</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626288 = query.getOrDefault("maxResults")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "maxResults", valid_21626288
  var valid_21626289 = query.getOrDefault("nextToken")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "nextToken", valid_21626289
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
  var valid_21626290 = header.getOrDefault("X-Amz-Date")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Date", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Security-Token", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Target")
  valid_21626292 = validateParameter(valid_21626292, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_21626292 != nil:
    section.add "X-Amz-Target", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Algorithm", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Signature")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Signature", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Credential")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Credential", valid_21626297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626299: Call_ListImages_21626285; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all the image IDs for the specified repository.</p> <p>You can filter images based on whether or not they are tagged by using the <code>tagStatus</code> filter and specifying either <code>TAGGED</code>, <code>UNTAGGED</code> or <code>ANY</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_21626299.validator(path, query, header, formData, body, _)
  let scheme = call_21626299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626299.makeUrl(scheme.get, call_21626299.host, call_21626299.base,
                               call_21626299.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626299, uri, valid, _)

proc call*(call_21626300: Call_ListImages_21626285; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for the specified repository.</p> <p>You can filter images based on whether or not they are tagged by using the <code>tagStatus</code> filter and specifying either <code>TAGGED</code>, <code>UNTAGGED</code> or <code>ANY</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626301 = newJObject()
  var body_21626302 = newJObject()
  add(query_21626301, "maxResults", newJString(maxResults))
  add(query_21626301, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626302 = body
  result = call_21626300.call(nil, query_21626301, nil, nil, body_21626302)

var listImages* = Call_ListImages_21626285(name: "listImages",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                        validator: validate_ListImages_21626286,
                                        base: "/", makeUrl: url_ListImages_21626287,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626303 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626305(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the tags for an Amazon ECR resource.
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
  var valid_21626306 = header.getOrDefault("X-Amz-Date")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Date", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Security-Token", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Target")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_21626308 != nil:
    section.add "X-Amz-Target", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Algorithm", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Signature")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Signature", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Credential")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Credential", valid_21626313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626315: Call_ListTagsForResource_21626303; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_21626315.validator(path, query, header, formData, body, _)
  let scheme = call_21626315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626315.makeUrl(scheme.get, call_21626315.host, call_21626315.base,
                               call_21626315.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626315, uri, valid, _)

proc call*(call_21626316: Call_ListTagsForResource_21626303; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_21626317 = newJObject()
  if body != nil:
    body_21626317 = body
  result = call_21626316.call(nil, nil, nil, nil, body_21626317)

var listTagsForResource* = Call_ListTagsForResource_21626303(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_21626304, base: "/",
    makeUrl: url_ListTagsForResource_21626305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_21626318 = ref object of OpenApiRestCall_21625435
proc url_PutImage_21626320(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImage_21626319(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <p>When an image is pushed and all new image layers have been uploaded, the PutImage API is called once to create or update the image manifest and tags associated with the image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21626321 = header.getOrDefault("X-Amz-Date")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Date", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Security-Token", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Target")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_21626323 != nil:
    section.add "X-Amz-Target", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Algorithm", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Signature")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Signature", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Credential")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Credential", valid_21626328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626330: Call_PutImage_21626318; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <p>When an image is pushed and all new image layers have been uploaded, the PutImage API is called once to create or update the image manifest and tags associated with the image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21626330.validator(path, query, header, formData, body, _)
  let scheme = call_21626330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626330.makeUrl(scheme.get, call_21626330.host, call_21626330.base,
                               call_21626330.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626330, uri, valid, _)

proc call*(call_21626331: Call_PutImage_21626318; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <p>When an image is pushed and all new image layers have been uploaded, the PutImage API is called once to create or update the image manifest and tags associated with the image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21626332 = newJObject()
  if body != nil:
    body_21626332 = body
  result = call_21626331.call(nil, nil, nil, nil, body_21626332)

var putImage* = Call_PutImage_21626318(name: "putImage", meth: HttpMethod.HttpPost,
                                    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                    validator: validate_PutImage_21626319,
                                    base: "/", makeUrl: url_PutImage_21626320,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageScanningConfiguration_21626333 = ref object of OpenApiRestCall_21625435
proc url_PutImageScanningConfiguration_21626335(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageScanningConfiguration_21626334(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the image scanning configuration for the specified repository.
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
  var valid_21626336 = header.getOrDefault("X-Amz-Date")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Date", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Security-Token", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Target")
  valid_21626338 = validateParameter(valid_21626338, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration"))
  if valid_21626338 != nil:
    section.add "X-Amz-Target", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Algorithm", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Signature")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Signature", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Credential")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Credential", valid_21626343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626345: Call_PutImageScanningConfiguration_21626333;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the image scanning configuration for the specified repository.
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_PutImageScanningConfiguration_21626333;
          body: JsonNode): Recallable =
  ## putImageScanningConfiguration
  ## Updates the image scanning configuration for the specified repository.
  ##   body: JObject (required)
  var body_21626347 = newJObject()
  if body != nil:
    body_21626347 = body
  result = call_21626346.call(nil, nil, nil, nil, body_21626347)

var putImageScanningConfiguration* = Call_PutImageScanningConfiguration_21626333(
    name: "putImageScanningConfiguration", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration",
    validator: validate_PutImageScanningConfiguration_21626334, base: "/",
    makeUrl: url_PutImageScanningConfiguration_21626335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_21626348 = ref object of OpenApiRestCall_21625435
proc url_PutImageTagMutability_21626350(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageTagMutability_21626349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the image tag mutability settings for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_21626351 = header.getOrDefault("X-Amz-Date")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Date", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Security-Token", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Target")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_21626353 != nil:
    section.add "X-Amz-Target", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Algorithm", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Signature")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Signature", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Credential")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Credential", valid_21626358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626360: Call_PutImageTagMutability_21626348;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the image tag mutability settings for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_21626360.validator(path, query, header, formData, body, _)
  let scheme = call_21626360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626360.makeUrl(scheme.get, call_21626360.host, call_21626360.base,
                               call_21626360.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626360, uri, valid, _)

proc call*(call_21626361: Call_PutImageTagMutability_21626348; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_21626362 = newJObject()
  if body != nil:
    body_21626362 = body
  result = call_21626361.call(nil, nil, nil, nil, body_21626362)

var putImageTagMutability* = Call_PutImageTagMutability_21626348(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_21626349, base: "/",
    makeUrl: url_PutImageTagMutability_21626350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_21626363 = ref object of OpenApiRestCall_21625435
proc url_PutLifecyclePolicy_21626365(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLifecyclePolicy_21626364(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or updates the lifecycle policy for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
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
  var valid_21626366 = header.getOrDefault("X-Amz-Date")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Date", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Security-Token", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Target")
  valid_21626368 = validateParameter(valid_21626368, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_21626368 != nil:
    section.add "X-Amz-Target", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Algorithm", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Signature")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Signature", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Credential")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Credential", valid_21626373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626375: Call_PutLifecyclePolicy_21626363; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates the lifecycle policy for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_21626375.validator(path, query, header, formData, body, _)
  let scheme = call_21626375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626375.makeUrl(scheme.get, call_21626375.host, call_21626375.base,
                               call_21626375.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626375, uri, valid, _)

proc call*(call_21626376: Call_PutLifecyclePolicy_21626363; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates the lifecycle policy for the specified repository. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_21626377 = newJObject()
  if body != nil:
    body_21626377 = body
  result = call_21626376.call(nil, nil, nil, nil, body_21626377)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_21626363(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_21626364, base: "/",
    makeUrl: url_PutLifecyclePolicy_21626365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_21626378 = ref object of OpenApiRestCall_21625435
proc url_SetRepositoryPolicy_21626380(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetRepositoryPolicy_21626379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Applies a repository policy to the specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_21626381 = header.getOrDefault("X-Amz-Date")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Date", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Security-Token", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Target")
  valid_21626383 = validateParameter(valid_21626383, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_21626383 != nil:
    section.add "X-Amz-Target", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Algorithm", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Signature")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Signature", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Credential")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Credential", valid_21626388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626390: Call_SetRepositoryPolicy_21626378; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a repository policy to the specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_21626390.validator(path, query, header, formData, body, _)
  let scheme = call_21626390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626390.makeUrl(scheme.get, call_21626390.host, call_21626390.base,
                               call_21626390.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626390, uri, valid, _)

proc call*(call_21626391: Call_SetRepositoryPolicy_21626378; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy to the specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_21626392 = newJObject()
  if body != nil:
    body_21626392 = body
  result = call_21626391.call(nil, nil, nil, nil, body_21626392)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_21626378(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_21626379, base: "/",
    makeUrl: url_SetRepositoryPolicy_21626380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageScan_21626393 = ref object of OpenApiRestCall_21625435
proc url_StartImageScan_21626395(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImageScan_21626394(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_21626396 = header.getOrDefault("X-Amz-Date")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Date", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Security-Token", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Target")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartImageScan"))
  if valid_21626398 != nil:
    section.add "X-Amz-Target", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Algorithm", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Signature")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Signature", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Credential")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Credential", valid_21626403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626405: Call_StartImageScan_21626393; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_21626405.validator(path, query, header, formData, body, _)
  let scheme = call_21626405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626405.makeUrl(scheme.get, call_21626405.host, call_21626405.base,
                               call_21626405.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626405, uri, valid, _)

proc call*(call_21626406: Call_StartImageScan_21626393; body: JsonNode): Recallable =
  ## startImageScan
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_21626407 = newJObject()
  if body != nil:
    body_21626407 = body
  result = call_21626406.call(nil, nil, nil, nil, body_21626407)

var startImageScan* = Call_StartImageScan_21626393(name: "startImageScan",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartImageScan",
    validator: validate_StartImageScan_21626394, base: "/",
    makeUrl: url_StartImageScan_21626395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_21626408 = ref object of OpenApiRestCall_21625435
proc url_StartLifecyclePolicyPreview_21626410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartLifecyclePolicyPreview_21626409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a preview of a lifecycle policy for the specified repository. This allows you to see the results before associating the lifecycle policy with the repository.
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
  var valid_21626411 = header.getOrDefault("X-Amz-Date")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Date", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Security-Token", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Target")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_21626413 != nil:
    section.add "X-Amz-Target", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Algorithm", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Signature")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Signature", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Credential")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Credential", valid_21626418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626420: Call_StartLifecyclePolicyPreview_21626408;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a preview of a lifecycle policy for the specified repository. This allows you to see the results before associating the lifecycle policy with the repository.
  ## 
  let valid = call_21626420.validator(path, query, header, formData, body, _)
  let scheme = call_21626420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626420.makeUrl(scheme.get, call_21626420.host, call_21626420.base,
                               call_21626420.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626420, uri, valid, _)

proc call*(call_21626421: Call_StartLifecyclePolicyPreview_21626408; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of a lifecycle policy for the specified repository. This allows you to see the results before associating the lifecycle policy with the repository.
  ##   body: JObject (required)
  var body_21626422 = newJObject()
  if body != nil:
    body_21626422 = body
  result = call_21626421.call(nil, nil, nil, nil, body_21626422)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_21626408(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_21626409, base: "/",
    makeUrl: url_StartLifecyclePolicyPreview_21626410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626423 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626425(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626424(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
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
  var valid_21626426 = header.getOrDefault("X-Amz-Date")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Date", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Security-Token", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Target")
  valid_21626428 = validateParameter(valid_21626428, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_21626428 != nil:
    section.add "X-Amz-Target", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Algorithm", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Signature")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Signature", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Credential")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Credential", valid_21626433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626435: Call_TagResource_21626423; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_21626435.validator(path, query, header, formData, body, _)
  let scheme = call_21626435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626435.makeUrl(scheme.get, call_21626435.host, call_21626435.base,
                               call_21626435.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626435, uri, valid, _)

proc call*(call_21626436: Call_TagResource_21626423; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_21626437 = newJObject()
  if body != nil:
    body_21626437 = body
  result = call_21626436.call(nil, nil, nil, nil, body_21626437)

var tagResource* = Call_TagResource_21626423(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
    validator: validate_TagResource_21626424, base: "/", makeUrl: url_TagResource_21626425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626438 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626440(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626439(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes specified tags from a resource.
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
  var valid_21626441 = header.getOrDefault("X-Amz-Date")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Date", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Security-Token", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Target")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_21626443 != nil:
    section.add "X-Amz-Target", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Algorithm", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Signature")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Signature", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Credential")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Credential", valid_21626448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626450: Call_UntagResource_21626438; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_21626450.validator(path, query, header, formData, body, _)
  let scheme = call_21626450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626450.makeUrl(scheme.get, call_21626450.host, call_21626450.base,
                               call_21626450.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626450, uri, valid, _)

proc call*(call_21626451: Call_UntagResource_21626438; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_21626452 = newJObject()
  if body != nil:
    body_21626452 = body
  result = call_21626451.call(nil, nil, nil, nil, body_21626452)

var untagResource* = Call_UntagResource_21626438(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_21626439, base: "/",
    makeUrl: url_UntagResource_21626440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_21626453 = ref object of OpenApiRestCall_21625435
proc url_UploadLayerPart_21626455(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UploadLayerPart_21626454(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <p>When an image is pushed, each new image layer is uploaded in parts. The maximum size of each image layer part can be 20971520 bytes (or about 20MB). The UploadLayerPart API is called once per each new image layer part.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_21626456 = header.getOrDefault("X-Amz-Date")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Date", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Security-Token", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Target")
  valid_21626458 = validateParameter(valid_21626458, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_21626458 != nil:
    section.add "X-Amz-Target", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Algorithm", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Signature")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Signature", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Credential")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Credential", valid_21626463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626465: Call_UploadLayerPart_21626453; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <p>When an image is pushed, each new image layer is uploaded in parts. The maximum size of each image layer part can be 20971520 bytes (or about 20MB). The UploadLayerPart API is called once per each new image layer part.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_21626465.validator(path, query, header, formData, body, _)
  let scheme = call_21626465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626465.makeUrl(scheme.get, call_21626465.host, call_21626465.base,
                               call_21626465.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626465, uri, valid, _)

proc call*(call_21626466: Call_UploadLayerPart_21626453; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <p>When an image is pushed, each new image layer is uploaded in parts. The maximum size of each image layer part can be 20971520 bytes (or about 20MB). The UploadLayerPart API is called once per each new image layer part.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_21626467 = newJObject()
  if body != nil:
    body_21626467 = body
  result = call_21626466.call(nil, nil, nil, nil, body_21626467)

var uploadLayerPart* = Call_UploadLayerPart_21626453(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_21626454, base: "/",
    makeUrl: url_UploadLayerPart_21626455, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}